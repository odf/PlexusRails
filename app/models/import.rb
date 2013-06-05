# The model associated with an individual import action.
#
# Instances of this model have a dual role: each instance receives a
# JSON-encoded collection of data node descriptions and, via an
# 'before_save' hook, establishes the corresponding entries in the
# database. After the import is completed, the instance retains the
# original JSON-source and in addition stores a log of the actions
# taken and their outcome.

class Import < ActiveRecord::Base
  # -- make 'pluralize' and such available (for logging)
  include ActionView::Helpers::TextHelper

  # -- add timestamps with user ids
  include Blame

  # t.datetime "source_timestamp"
  # t.string   "sample_id"
  # t.text     "content"
  # t.text     "source_log"
  # t.text     "import_log"
  # t.string   "description"
  # t.datetime "created_at"
  # t.datetime "updated_at"

  # -- associations
  belongs_to :user
  belongs_to :sample

  # -- before saving, perform the actions prescribed by this import
  before_save :run_this_import

  # -- pseudo-attributes for use with Rails-generated forms
  def data=(value)
    write_attribute(:content, value.read)
  end

  def time=(value)
    self.source_timestamp = value.blank? ? nil : Time.parse(value).utc
  end

  # -- JSON-powered accessors
  [:content, :import_log].each do |attr|
    define_method(attr) do
      begin
        JSON::load((read_attribute(attr) || "{}").strip)
      rescue
        read_attribute(attr) || ""
      end
    end

    define_method("#{attr}=") do |data|
      write_attribute(attr, data.to_json)
    end
  end

  # -- permissions are as in the sample this import belongs to
  def allows?(action, user)
    sample.allows?(action, user)
  end

  private

  # After-create hook to perform the import action prescribed by this
  # instance. This will typically create a number of data nodes and
  # the interconnections between them. A log of the performed actions
  # is saved to the database as a part of the table row associated
  # with this instance.
  def run_this_import
    return unless import_log.blank?

    # -- preparations
    result = {
      'User' => user && user.name,
      'Date' => (source_timestamp or '').to_s,
      'Project' => sample.project.name,
      'Sample' => "#{sample.external_id} (#{sample.name})",
      'Nodes' => [],
      'Status' => 'UNSUPPORTED'
    }
    nodes_created = 0
    predecessors = {}
    predecessors.default = []
    @name2node = {}
    @name2node.default = []

    # -- create new nodes
    content.each do |entry|
      log = handle_node(entry)
      result["Nodes"] << log
      if log["IsMain"] and log["Status"] == "Success"
        result["MainNodeID"] = log["Id"]
        result["MainNodeExternalID"] = log["ExternalID"]
      end
      predecessors[log["Id"]] += entry["predecessors"]
      nodes_created += 1 if log["Created"]
    end

    # -- create database links between the nodes in this import
    link_log = link_predecessors(predecessors)
    
    # -- compose a log for this import
    status = result["Nodes"].map { |x| x["Status"] }
    result["Status"] = status.include?("Failure") ? "Mixed" : "Success"
    result["Messages"] =
      ["Created #{pluralize nodes_created, "data node"}."] + (link_log || [])

    # -- set the log attribute
    self.import_log = result

    # -- force save to create external id on sample if missing
    self.sample.save!

  rescue Exception => ex
    result ||= {}
    result["Status"] = 'Error'
    result["Messages"] = [ex.to_s] + ex.backtrace[0,50]
    self.import_log = result
  end

  # Performs the necessary update actions for a single data node. The
  # node is created if it doesn't already exist. Otherwise, a check
  # for inconsistencies is done and information added to the existing
  # node if appropriate.
  #
  # *Arguments*:
  # _entry_:: a hash describing the data node to create.
  def handle_node(entry)
    messages = []

    # -- check for conflicts with existing nodes
    existing = find_nodes_like(entry)
    problems =
      check_conflicts(entry, existing.select { |n| n.status == 'valid' })
    valid = problems.empty?
    msgs_for_node = (entry["parse_errors"] + problems).join("\n")

    # -- create the node if it doesn't exist
    if existing.empty? or (not valid and not find_rejected(entry, msgs_for_node))
      node = create_node(entry, valid, msgs_for_node)
      messages << "Node created."
      if resolve_if_pending(node) > 0
        messages << "Node resolves missings inputs."
      end
      created = true
    else
      node = existing[0]
      messages << "Node existed; #{problems.empty? ? "no" : "some"} conflicts."
      created = false
    end

    # -- add any new information to the node
    res = add_missing_info(node, entry)
    messages += res[:messages]
    problems += res[:errors]
    is_main = res[:is_main]

    # -- remember the node created for later lookup by name
    @name2node[entry["name"]] += [ node ]

    # -- add some loggin information
    status = problems.empty? ? "Success" : "Failure"
    messages = entry["parse_errors"].map { |s| "(PARSE ERROR) #{s}" } +
      messages + problems
    
    # -- return some information to the caller
    {
      "Name" => entry["name"],
      "Status" => status,
      "Created" => created,
      "Messages" => messages,
      "Id" => node.id,
      "ExternalID" => node.identifier,
      "IsMain" => is_main
    }
  end

  # Looks for existing data node entries in the database which match
  # the given attributes. This procedes in a number of steps which are
  # tried in order. The first step that produces a non-empty list of
  # results returns those results. If no valid nodes are found, the
  # same sequence of steps is performed on the invalid nodes.
  #
  # *Arguments*:
  # _entry_:: a hash containing data node attributes.
  def find_nodes_like(entry)
    # -- some preparation
    names = [entry["name"]]
    names << entry["data_file"]["name"] unless entry["data_file"].blank?
    ident = entry["identifier"]

    # -- search valid nodes first, then invalid ones
    for status in %w{valid error}
      # -- look for matching identifiers
      unless ident.blank?
        nodes = sample.data_nodes.where :identifier => ident, :status => status
        return nodes unless nodes.empty?
      end

      # -- the timestamp must always match precisely
      date = parse_timestamp(entry)
      candidates = sample.data_nodes.where(:status => status).
        joins(:producer).where('date = ?', date)

      # -- match given node name, then file name, with existing node names
      for field in [:name, :filename]
        for name in names
          nodes = candidates.where field => name
          return nodes unless nodes.empty?
        end
      end
    end

    # -- if this point is reached, nothing was found
    return []
  end

  def find_rejected(entry, msgs)
    sample.data_nodes.where(:identifier => entry['identifier'],
                            :status => 'error',
                            :messages => msgs)
  end

  # Checks for inconsistencies between a data node descriptor and a
  # list of existing DataNode instances in the database.
  #
  # *Arguments*:
  # _entry_:: a hash containing attributes for a data node
  # _nodes_:: an array of nodes to compare with
  def check_conflicts(entry, nodes)
    # -- start with an empty list of inconsistency messages
    problems = []

    # -- there should have been only one node to compare with
    if nodes.size > 1
      problems <<
        "(WARNING) Multiple matching data nodes exist in the database."
    end

    # -- loop over the nodes given
    for node in nodes
      # -- check for inconsistent file names
      if entry["data_file"] and not node.filename.blank?
        if node.filename != entry["data_file"]["name"]
          problems <<
            "(ERROR) Data is already associated with file '#{node.filename}'."
        end
      end

      # -- check for mismatches in the history entries
      if node.producer.history != entry["source_text"]
        problems << "(ERROR) History mismatch."
      end

      # -- check for data domain mismatches
      (entry["domain"] || {}).each do |key, val|
        old = node.send key
        if val.class == Float && old.class == Float
          changed = (val - old).abs / val > 1e-4
        elsif not (val.blank? or old.blank?)
          changed = (val != old);
        end
        if changed
          problems << "(ERROR) Domain mismatch: '#{key}' was #{old}, is #{val}."
        end
      end
    end

    # -- check for uniqueness of fingerprint
    fp = fingerprint(entry, problems.empty?)
    found =
      DataNode.where("fingerprint = ? AND sample_id != ? AND status = 'valid'",
                     fp, sample.id)
    if found.count > 0
      other = found.first
      problems << ("(ERROR) Duplicates dataset '#{other.name}'" +
                   " from sample '#{other.sample.name}'" +
                   " in project '#{other.sample.project.name}'")
    end

    # -- return the list of inconsistency messages
    problems
  end

  # Creates a DataNode instance in the database with the given
  # attributes.
  #
  # *Arguments*:
  # _entry_:: a hash containing the attributes for the new node
  # _valid_:: a boolean indicating whether the node is valid
  # _messages_:: string of error and warning messages for this node
  def create_node(entry, valid, messages)
    process = sample.process_nodes.create(:date       => parse_timestamp(entry),
                                          :data_type  => entry["process"],
                                          :run_by     => entry["run_by"],
                                          :history    => entry["source_text"],
                                          :output_log => entry["output_log"],
                                          :parameters => entry["parameters"])

    node = sample.data_nodes.create(:producer_id => process.id,
                                    :name        => entry["name"],
                                    :fingerprint => fingerprint(entry, valid),
                                    :data_type   => entry["data_type"],
                                    :identifier  => entry["identifier"],
                                    :messages    => messages,
                                    :status      => valid ? 'valid' : 'error',
                                    :hidden      => false)

    node
  end

  def fingerprint(entry, valid)
    require 'digest/md5'

    md5 = Digest::MD5.new
    for key in %w{name identifier date data_type process source_text}
      md5.update(entry[key] || "")
    end
    md5.update "error #{sample}" unless valid

    md5.hexdigest
  end

  # Updates an existing DataNode instance with the given information.
  #
  # *Arguments*:
  # _node_:: the data node to update
  # _entry_:: a hash containing the new information
  def add_missing_info(node, entry)
    # -- prepare a return value
    info = {
      :messages => [],
      :errors => [],
      :is_main => false
    }

    # -- update the data domain if necessary
    if entry["domain"] && node.domain_origin.empty?
      d = entry["domain"]
      node.domain_origin = [d["domain_origin_x"] || '?',
                            d["domain_origin_y"] || '?',
                            d["domain_origin_z"] || '?']
      node.domain_size = [d["domain_size_x"] || '?',
                          d["domain_size_y"] || '?',
                          d["domain_size_z"] || '?']
      node.voxel_size = [d["voxel_size_x"] || '?',
                         d["voxel_size_y"] || '?',
                         d["voxel_size_z"] || '?']
      node.voxel_unit = d["voxel_unit"]

      info[:messages] << "Domain information added."
    end

    # -- update information on the source file for this entry
    if entry["data_file"]
      info[:is_main] = true

      # -- set the filename if missing
      if node.filename.nil?
        node.filename = entry["data_file"]["name"]
        info[:messages] << "Filename set."
      end

      # -- update the synchronization date
      date = parse_timestamp(entry["data_file"])
      if node.synchronized_at.nil? or node.synchronized_at < date
        node.synchronized_at = date
        info[:messages] << "File synchronization timestamp updated."
      end
    end

    # -- save the node if necessary
    node.save!

    # -- return some info on what's been done
    info
  end

  # Establish new predecessor ("input") links between the DataNode
  # instances where necessary.
  #
  # *Arguments*:
  # _predecessors_:: a data structure describing predecessor relation.
  def link_predecessors(predecessors)
    # -- initialize an error log
    log = []

    # -- each list entry links an internal node id to a list of predecessors
    for (node_id, specs) in predecessors
      # -- locate the specified node
      node = sample.data_nodes.find(node_id)

      # -- process the given list of predecessors
      for item in specs
        # -- extract attributes that identify this predecessor
        name = item["name"]
        ident = item["identifier"]
        msg = item.delete("message")

        # -- preserve a possible error message
        unless msg.blank?
          blame = ident || name
          blame = "UNNAMED" if blame.blank?
          log << "(PARSER) #{blame}: #{msg}"
        end

        # -- find the node described
        candidates = if ident == nil
                       @name2node[name]
                     else
                       sample.data_nodes.where(:identifier => ident).to_a
                     end

        if candidates.size == 1
          pre = candidates.first
        else
          # -- too many or too few candidates - create a log entry
          msg = candidates.empty? ? "not found" : "ambigous"
          log << "Predecessor #{ident || name} #{msg} for node '#{node.name}'."
          # -- if an external identifier was given, create a placeholder
          if ident
            pre = sample.data_nodes.build(:name       => name,
                                           :identifier => ident,
                                           :status     => 'missing')
            pre.save!
          else
            pre = nil
          end
        end

        if pre
          # -- create the predecessor link if it wouldn't create a cycle
          if node.descendants.include?(pre)
            log << "(WARNING) Making '#{pre.name}' a predecessor of " +
              "'#{node.name}' would create a cycle."
          else
            sample.add_link(pre, node)
          end
        end
      end
    end

    # -- return the error log
    log
  end

  # Replaces any references to placeholder ("missing") data nodes with
  # the same identifier as the given node by references to the given
  # node. Returns the number of placeholder nodes found.
  #
  # *Arguments*:
  # _node_:: the DataNode instance to resolve pending references for
  def resolve_if_pending(node)
    # -- load the placeholders for this node into an array
    pending = sample.data_nodes.where(:status => 'missing',
                                       :identifier => node.identifier).to_a

    # -- link the new node to each successor
    pending.each { |v| v.successors.each { |w| sample.add_link(node, w) } }

    # -- remove the placeholders
    pending.each(&sample.method(:destroy_node))

    # -- return the number of nodes replaced
    pending.count
  end

  # Utility method. Creates a Time instance from a string attribute
  # contained in a hash.
  #
  # *Arguments*:
  # _entry_:: a hash containing data node attributes
  def parse_timestamp(entry)
    Time.parse(entry["date"]).getutc unless entry["date"].blank?
  end
end
