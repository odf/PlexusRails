class Project < ActiveRecord::Base
  include Blame

  # t.string   "name"
  # t.string   "organization"
  # t.datetime "created_at"
  # t.datetime "updated_at"

  # -- associations
  has_many :samples, :dependent => :destroy
  has_many :memberships, :dependent => :destroy
  has_many :members, :through => :memberships, :source => :user
  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :images, :as => :illustratable, :dependent => :destroy

  # -- whitespace in the project name is normalized to single spaces
  before_validation do |project|
    project.name = project.name.strip.gsub(/\s+/, ' ')
  end

  # -- make sure project names are unique (case-insensitive)
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }

  # -- methods to inquire project memberships and user permissions
  def role_of(user)
    (m = membership_of(user)) && m.role
  end

  def allows?(action, user)
    role = role_of(user)
    case action.to_sym
    when :view
      user and user.may_view and not role.nil?
    when :edit
      user and user.may_edit and %w{contributor manager}.include? role
    when :manage
      user and user.may_edit and (user.may_authorize or role == 'manager')
    when :upload
      user and user.may_upload
    else
      false
    end
  end

  # -- pseudo-attribute for editing memberships and roles
  attr_accessor :_manager

  def roles
    User.sorted.map do |user|
      membership_of(user) ||
        Membership.new(:user => user,
                       :role => (user == _manager) ? 'manager' : '')
    end
  end

  def roles_attributes=(data)
    data.each { |key, value| set_role(User.find(value[:user_id]), value[:role]) }
  end

  # Assigns the given user the given role.
  def set_role(user, role)
    membership = membership_of(user)

    if membership
      if role.blank?
        membership.destroy
      else
        membership.update_attributes(:role => role)
      end
    elsif user and not role.blank?
      memberships.build(:user => user, :role => role)
    end
  end

  # -- private methods start here
  private

  def membership_of(user)
    user && memberships.where(:user_id => user.id).first
  end
end
