class Project
  include Mongoid::Document

  field :name, :type => String, :accessible => false
  field :organization, :type => String
  key :name

  validates :name, :presence => true, :strong_uniqueness => true
end
