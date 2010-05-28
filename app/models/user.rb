class User
  READER_FU = [ 'login', 'view' ]
  EDITOR_FU = READER_FU + [ 'edit' ]
  ADMIN_FU  = EDITOR_FU + [ 'authorize' ]
  WIZARD_FU = ADMIN_FU + [ 'impersonate' ]
  ABILITIES = WIZARD_FU

  # -- we use MongoDB via the Mongoid gem to store this model
  include Mongoid::Document

  # -- declaration of persistent fields
  field :login_name, :type => String, :accessible => false
  field :hashed_password, :type => String, :accessible => false
  field :first_name, :type => String
  field :last_name, :type => String
  field :email, :type => String
  field :crypt_strength, :type => Integer, :default => 4, :accessible => false
  field :organization, :type => String
  field :homepage, :type => String
  field :abilities, :type => Array, :default => READER_FU
  key :login_name

  # -- these fields are used in forms but not stored
  attr_accessor :password, :password_confirmation

  # -- we define some roles as named scopes
  named_scope :reader, :where => { :abilities.all => READER_FU }
  named_scope :editor, :where => { :abilities.all => EDITOR_FU }
  named_scope :admin,  :where => { :abilities.all => ADMIN_FU }
  named_scope :wizard, :where => { :abilities.all => WIZARD_FU }

  # -- the validations for this model
  validates :login_name,
    :strong_uniqueness => true,
    :format => {
      :with => /\A([a-z0-9.-]*)?\Z/i,
      :message => 'may only contain letters, digits, hyphens and dots'
    },
    :length => { :minimum => 3, :maximum => 40 }
  
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

  # Finds the user with the given login name and password, if any.
  def self.authenticate(login_name, password)
    user = self.where(:login_name => login_name).first
    user if user and Crypt::check(password, user.hashed_password,
                                  :strength => user.crypt_strength)
  end
  
  # The displayed name for this user.
  def name
    "#{first_name} #{last_name}"
  end

  ABILITIES.each do |a|
    define_method("may_#{a}") do
      abilities.include? a
    end

    define_method("may_#{a}=") do |val|
      self.abilities = (val and val != '0') ? abilities | [a] : abilities - [a]
    end
  end
end
