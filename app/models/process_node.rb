# The model to represent a process node.

class ProcessNode
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- simple persistent attributes
  field :date,       :type => Time
  field :run_by,     :type => String
  field :data_type,  :type => String
  field :history,    :type => String
  field :output_log, :type => String
  field :input_ids,  :type => Array, :default => []

  # -- associations
  embedded_in :project, :inverse_of => :process_nodes

  # -- accessors for input nodes
  def inputs
    project.data_nodes.any_in(:_id => input_ids)
  end

  def inputs=(list)
    self.input_ids = list.map { |value| value._id }
  end

  def add_input(value)
    unless input_ids.include? value._id
      input_ids << value._id 
      save!
    end
  end
end
