# The model associated with an individual import action.
#
# Instances of this model have a dual role: each instance receives a
# JSON-encoded collection of data node descriptions and, via an
# 'before_save' hook, establishes the corresponding entries in the
# database. After the import is completed, the instance retains the
# original JSON-source and in addition stores a log of the actions
# taken and their outcome.

class Import
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- make 'pluralize' and such available (for logging)
  include ActionView::Helpers::TextHelper

  # -- add timestamps with user ids
  include Timestamps

  # -- simple persistent attributes
  field :source_timestamp, :type => Time
  field :sample_name,      :type => String
  field :content,          :type => Hash
  field :source_log,       :type => String
  field :import_log,       :type => Hash
  field :description,      :type => String

  # -- associations
  referenced_in :user
  embedded_in :project, :inverse_of => :imports

  # -- before saving, perform the actions prescribed by this import
  before_save :run_this_import

  # -- pseudo-attributes for use with Rails-generated forms
  def data=(value)
    self.content = JSON::load(value.read)
  end

  def time=(value)
    time_args = ParseDate::parsedate(value) unless value.blank?
    self.source_timestamp = time_args ? Time.local(*time_args).utc : nil
  end

  def sample=(value)
    self.sample_name = value
  end

  # -- permissions are as in the project this import belongs to
  def allows?(action, user)
    project.allows?(action, user)
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
      'Project' => project.name,
      'Sample' => sample_name, # "#{sample.name} (#{sample.nickname})",
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

  rescue Exception => ex
    result ||= {}
    result["Status"] = 'Error'
    result["Messages"] = [ex.to_s] + ex.backtrace[0,10]
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
    if existing.empty? or not (valid or find_rejected(entry, msgs_for_node))
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
        nodes = project.data_nodes.where :identifier => ident, :status => status
        return nodes unless nodes.empty?
      end

      # -- the timestamp must always match precisely
      date = parse_timestamp(entry)
      candidates = project.data_nodes.where :date => date, :status => status

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

  # Creates a DataNode instance in the database with the given
  # attributes.
  #
  # *Arguments*:
  # _entry_:: a hash containing the attributes for the new node
  # _valid_:: a boolean indicating whether the node is valid
  # _messages_:: string of error and warning messages for this node
  def create_node(entry, valid, messages)
    status = valid ? 'valid' : 'error'

    node = project.data_nodes.build(:name       => entry["name"],
                                    :sample     => sample_name,
                                    :data_type  => entry["data_type"],
                                    :identifier => entry["identifier"],
                                    :messages   => messages,
                                    :status     => status,
                                    :hidden     => false)

    process = project.process_nodes.build(:date       => parse_timestamp(entry),
                                          :data_type  => entry["process"],
                                          :run_by     => entry["run_by"],
                                          :history    => entry["source_text"],
                                          :output_log => entry["output_log"])

    #TODO - create process attributes

    node.producer = process
    process.save!
    node.save!

    node
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
      :is_main => false
    }

    # -- update the data domain if necessary
    if entry["domain"] && !node.domain
      node.build_domain(entry["domain"])
      info[:messages] << "Domain entry added."
    end

    # -- update information on the source file for this entry
    if entry["data_file"]
      name = entry["data_file"]["name"]
      date = parse_timestamp(entry["data_file"])
      info[:is_main] = true

      # -- set the filename if missing
      if node.filename.nil?
        node.filename = name
        info[:messages] << "Filename set."
      end

      # -- update the synchronization date
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
      node = project.data_nodes.where(:_id => node_id).first

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
                       project.data_nodes.where(:identifier => ident).to_a
                     end

        if candidates.size == 1
          pre = candidates.first
        else
          # -- too many or too few candidates - create a log entry
          msg = candidates.empty? ? "not found" : "ambigous"
          log << "Predecessor #{ident || name} #{msg} for node '#{node.name}'."
          # -- if an external identifier was given, create a placeholder
          if ident
            pre = project.data_nodes.build(:name       => name,
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
            project.add_link(pre, node)
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
    pending = project.data_nodes.where(:status => 'missing',
                                       :identifier => node.identifier).to_a

    # -- link the new node to each successor
    pending.each { |v| v.successors.each { |w| project.add_link(node, w) } }

    # -- remove the placeholders
    pending.each(&project.method(:destroy_node))

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


  #TODO - Placeholder methods to be fleshed out later
  def check_conflicts(entry, nodes)
    []
  end
end
