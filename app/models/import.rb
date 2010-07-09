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

    # -- add a log entry to the database
    status = problems.empty? ? "Success" : "Failure"
    messages = entry["parse_errors"].map { |s| "(PARSE ERROR) #{s}" } +
      messages + problems
    
    #TODO implement data logs
    #data_logs.create(:data_node_id => node.id,
    #                 :status => status, :messages => messages)

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

  def create_node(entry, valid, messages)
    status = valid ? 'valid' : 'error'
    node = project.data_nodes.build(:name       => entry["name"],
                                    :data_type  => entry["data_type"],
                                    :identifier => entry["identifier"],
                                    :messages   => messages,
                                    :status     => status,
                                    :hidden     => false)
    node.save!
    node

    #TODO - create the associated process node
  end

  #TODO - Placeholder methods to be fleshed out later
  def find_nodes_like(entry)
    []
  end

  def check_conflicts(entry, nodes)
    []
  end

  def resolve_if_pending(node)
    0
  end

  def add_missing_info(node, entry)
    {
      :messages => [],
      :is_main => false
    }
  end

  def link_predecessors(predecessors)
    []
  end
end
