# The model to represent a data node.

class DataNode
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- simple persistent attributes
  field :name,       :type => String
  field :data_type,  :type => String
  field :identifier, :type => String
  field :messages,   :type => String
  field :status,     :type => String
  field :hidden,     :type => Boolean

  # -- associations
  embedded_in :project, :inverse_of => :data_nodes
end
