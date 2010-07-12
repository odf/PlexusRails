# The model to represent a data node.

class DataNode
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- simple persistent attributes
  field :sample,          :type => String
  field :name,            :type => String
  field :data_type,       :type => String
  field :identifier,      :type => String
  field :messages,        :type => String
  field :status,          :type => String
  field :hidden,          :type => Boolean
  field :filename,        :type => String
  field :synchronized_at, :type => Time
  field :producer_id,     :type => String

  # -- associations
  embedded_in :project, :inverse_of => :data_nodes
  embeds_one :domain

  # -- some named scopes
  named_scope :visible, :where => { :hidden => false }
  named_scope :by_id, :order_by => :identifier
  named_scope :by_sample, :order_by => :sample

  # -- accessors for the producer
  def producer
    producer_id && project.process_nodes.where(:_id => producer_id).first
  end

  def producer=(value)
    self.producer_id = value._id
  end

  # -- convenience methods
  def date
    producer && producer.date
  end

  def predecessors
    producer.inputs
  end
end
