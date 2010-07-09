# The model to represent a data node.

class DataNode
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- simple persistent attributes
  field :sample,          :type => String
  field :name,            :type => String
  field :date,            :type => Time
  field :data_type,       :type => String
  field :identifier,      :type => String
  field :messages,        :type => String
  field :status,          :type => String
  field :hidden,          :type => Boolean
  field :filename,        :type => String
  field :synchronized_at, :type => Time

  # -- associations
  embedded_in :project, :inverse_of => :data_nodes
  embeds_one :domain

  # -- some named scopes
  named_scope :visible, :where => { :hidden => false }
  named_scope :by_id, :order_by => :identifier
  named_scope :by_sample, :order_by => :sample
end
