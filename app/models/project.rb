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

  index 'memberships.role'

  # -- whitespace in the project name is normalized to single spaces
  before_validate do |project|
    project.name = project.name.strip.gsub(/\s+/, ' ')
  end
  
  # -- make sure project names are unique (case-insensitive)
  validates :name, :presence => true, :strong_uniqueness => true

  def members
    memberships.map &:user
  end

  def membership_of(user)
    memberships.where(:user_id => user.id).first
  end

  def role_of(user)
    (m = membership_of(user)) && m.role
  end

  def can_be_viewed_by(user)
    %w{client contributor manager}.include? role_of(user)
  end

  def can_be_edited_by(user)
    %w{contributor manager}.include? role_of(user)
  end

  def can_be_managed_by(user)
    role_of(user) == 'manager'
  end

  def roles
    User.sorted.map do |user|
      membership_of(user) || Membership.new(:user => user, :role => '')
    end
  end

  def roles_attributes=(data)
    data.each { |key, value| set_role(User.find(value[:user_id]), value[:role]) }
  end

  private
  def set_role(user, role)
    membership = user && memberships.where(:user_id => user.id).first

    if membership
      if role.blank?
        membership.destroy
      else
        membership.update_attributes(:role => role)
      end
    elsif user and not role.blank?
      memberships.create(:user_id => user.id, :role => role)
    end
  end
end
