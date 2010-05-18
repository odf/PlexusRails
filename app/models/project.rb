class Project
  include Mongoid::Document

  field :name, :type => String
  field :organization, :type => String

  validates_presence_of :name
end
