class Project
  include Mongoid::Document

  field :name, :type => String, :accessible => false
  field :organization, :type => String
  key :name

  before_validate do |project|
    project.name = project.name.strip.gsub(/\s+/, ' ')
  end

  validates :name, :presence => true, :strong_uniqueness => true
end
