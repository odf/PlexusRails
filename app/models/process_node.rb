# The model to represent a process node.

class ProcessNode < ActiveRecord::Base
  # -- simple persistent attributes
  # field :date,       :type => Time
  # field :run_by,     :type => String
  # field :data_type,  :type => String
  # field :history,    :type => String
  # field :output_log, :type => String
  # field :parameters, :type => Hash, :default => {}
  # field :input_ids,  :type => Array, :default => []

  # -- associations
  belongs_to :project

  # -- accessors for input nodes
  def inputs
    input_ids.split(' ').map &project.data_nodes.method(:find)
  end

  def inputs=(list)
    self.input_ids = list.map { |v| v.id.to_s }.join(' ')
  end

  def add_input(value)
    unless inputs.map(&:id).include? value._id
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
