# The model to represent a process node.

class ProcessNode
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- simple persistent attributes
  field :date,       :type => String
  field :run_by,     :type => String
  field :data_type,  :type => String
  field :history,    :type => String
  field :output_log, :type => String
  field :input_ids,  :type => Array

  # -- associations
  embedded_in :project, :inverse_of => :process_nodes

  # -- accessors for input nodes
  def inputs
    project.data_nodes.any_in(:_id => input_ids)
  end

  def inputs=(list)
    input_ids = list.map { |value| value._id }
  end
end
