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
  named_scope :visible,   :where => { :hidden => false }
  named_scope :resolved,  :where => { :status.ne => 'missing' }
  named_scope :missing,   :where => { :status => 'missing' }
  named_scope :by_id,     :order_by => :identifier
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
    find_nodes project.graph.pred(self._id)
  end

  def successors
    find_nodes project.graph.succ(self._id)
  end

  def descendants
    find_nodes project.graph.reachable(self._id)
  end

  def ancestors
    adj = project.graph.method(:pred)
    find_nodes Persistent::Depth_First_Traversal.new([self._id], &adj)
  end

  private
  def find_nodes(nodes)
    nodes.map { |v| project.data_nodes.where(:_id => v).first }
  end
end
