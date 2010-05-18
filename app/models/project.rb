class Project
  include Mongoid::Document

  field :name, :type => String
  field :organization, :type => String

  validates :name, :presence => true, :uniqueness => true
end
