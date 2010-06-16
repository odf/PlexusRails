class Project
  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- declaration of persistent fields
  field :name, :type => String, :accessible => false
  field :organization, :type => String

  # -- what to use as the document key
  key :name

  # -- embedded and related documents
  embeds_many :memberships

  # -- whitespace in the project name is normalized to single spaces
  before_validate do |project|
    project.name = project.name.strip.gsub(/\s+/, ' ')
  end
  
  # -- make sure project names are unique (case-insensitive)
  validates :name, :presence => true, :strong_uniqueness => true

  # -- allows for nicer forms
  accepts_nested_attributes_for :memberships


  def members
    memberships.map &:user
  end

  def set_role(user, role)
    membership = user && memberships.where(:user_id => user.id).first

    if membership
      if role.blank?
        membership.destroy
      else
        membership.update_attributes(:role => role)
      end
    elsif user
      memberships.create(:user_id => user.id, :role => role)
    end
  end
end
