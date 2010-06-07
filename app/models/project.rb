class Project
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- declaration of persistent fields
  field :name, :type => String, :accessible => false
  field :organization, :type => String
  key :name

  # -- whitespace in the project name is normalized to single spaces
  before_validate do |project|
    project.name = project.name.strip.gsub(/\s+/, ' ')
  end
  
  # -- make sure project names are unique (case-insensitive)
  validates :name, :presence => true, :strong_uniqueness => true
end
