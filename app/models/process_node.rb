# The model to represent a process node.

class ProcessNode < ActiveRecord::Base
  # t.datetime "date"
  # t.string   "run_by"
  # t.string   "data_type"
  # t.text     "history"
  # t.text     "output_log"
  # t.text     "parameters"
  # t.text     "input_ids"

  # -- associations
  belongs_to :project
  has_many :outputs, :class_name => 'DataNode', :foreign_key => 'producer_id'

  # -- accessors for input nodes
  def inputs
    (input_ids || '').split(' ').map { |v| project.data_nodes.find(v) }
  end

  def inputs=(list)
    self.input_ids = list.map { |v| v.id.to_s }.join(' ')
  end

  def add_input(value)
    unless inputs.map(&:id).include? value.id
      self.inputs = inputs + [value]
      save!
    end
  end

  # -- accessors for parameters
  def parameters
    JSON::load(read_attribute(:parameters))
  end

  def parameters=(data)
    write_attribute(:parameters, data.to_json)
  end
end
