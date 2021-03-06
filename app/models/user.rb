class User < ActiveRecord::Base
  # -- sets of abilities for certain roles
  READER_TASKS = [ 'login', 'view' ]
  EDITOR_TASKS = READER_TASKS + [ 'edit' ]
  ADMIN_TASKS  = EDITOR_TASKS + [ 'authorize', 'upload' ]
  WIZARD_TASKS = ADMIN_TASKS + [ 'impersonate' ]
  ABILITIES    = WIZARD_TASKS

  # -- fields
  include Blame

  # t.string   "login_name"
  # t.string   "hashed_password"
  # t.string   "first_name"
  # t.string   "last_name"
  # t.string   "email"
  # t.integer  "crypt_strength",  :default => 4
  # t.string   "organization"
  # t.string   "homepage"
  # t.string   "abilities",       :default => "login view"
  # t.datetime "created_at"
  # t.datetime "updated_at"

  # -- associations
  has_one  :activity_log
  has_many :memberships
  has_many :projects, :through => :memberships, :source => :project
  has_many :comments, :foreign_key => :author_id
  has_many :imports

  # -- these fields are used in forms but not stored
  attr_accessor :password, :password_confirmation

  # -- named scopes for selecting by role and for sorting
  scope :sorted, :order => [:last_name, :first_name]

  # -- the validations for this model
  validates :login_name,
    :uniqueness => { :case_sensitive => false },
    :format => {
      :with => /\A([a-z0-9.-]*)?\Z/i,
      :message => 'may only contain letters, digits, hyphens and dots'
    },
    :length => { :minimum => 3, :maximum => 40 },
    :presence => { :on => :create }

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  
  validates :email, :presence => true, :format => {
    :with => /\A([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4})?\Z/i,
    :message => 'does not look like an email address'
  }

  validates :homepage, :format => {
    :with => /\A(http:\/\/[A-Z0-9.-]+\.[A-Z]{2,4}(\/[A-Z0-9.-~]*)*)?\Z/i,
    :message => 'does not look like a URL'
  }

  validates :password, :presence => { :on => :create }
  validates :password_confirmation, :presence => { :on => :create }

  validates_each :password do |user, attr, value|
    if value.blank?
      user.errors[attr] << "can't be blank" if user.hashed_password.blank?
    elsif value.size < 6
      user.errors[attr] << "must have at least 6 characters"
    elsif value.size > 20
      user.errors[attr] << "may have at most 20 characters"
    elsif user.password_confirmation != value
      user.errors[:password_confirmation] << "does not match"
    end
  end

  # -- this produces the encrypted password for persistent storage
  before_save do |user|
    unless user.password.blank?
      user.hashed_password =
        Crypt::crypt(user.password, :strength => user.crypt_strength)
    end
  end

  # Make the abilities attribute look like an array
  def abilities
    (read_attribute(:abilities) || '').split(' ')
  end

  def abilities=(values)
    write_attribute(:abilities, (values || []).join(' '))
  end

  # Finds the user with the given login name and password, if any.
  def self.authenticate(params)
    login_name = params[:login_name] || params[:name]
    password = params[:password]
    user = self.where(:login_name => login_name).first
    user if user and Crypt::check(password, user.hashed_password,
                                  :strength => user.crypt_strength)
  end
  
  # The displayed name for this user.
  def name
    "#{first_name} #{last_name}"
  end
  
  # The name of the method that checks the given ability for a user.
  def self.ability_getter(a)
    "may_#{a}".to_sym
  end

  # The name of the method that adds or removes the given ability.
  def self.ability_setter(a)
    "may_#{a}=".to_sym
  end

  # -- define the getters and setters for all supported abilities
  ABILITIES.each do |a|
    define_method(ability_getter(a)) do
      abilities.include? a
    end

    define_method(ability_setter(a)) do |val|
      self.abilities = (val and val != '0') ? abilities | [a] : abilities - [a]
    end
  end

  # Checks whether the given user can perform the given action on this instance
  def allows?(action, user)
    case action.to_sym
    when :view then user.may_edit or user == self
    when :edit then user.may_authorize or user == self
    else            false
    end
  end

  # Checks whether this user can add or remove ability <a> for user <user>.
  def can_authorize?(user, a)
    user != self and may_authorize and
      (abilities | ADMIN_TASKS).include?(a)
  end

  # Logs an action (page view) for this user
  def log_activity(at, action = nil)
    unless activity_log
      update_attributes(:activity_log => ActivityLog.create(:user => self))
    end
    activity_log.add(at, action)
  end

  # Get the time of the last time the user was active
  def last_active
    activity_log && activity_log.last_time
  end
end
