class User
  include Mongoid::Document

  field :login_name, :type => String
  field :hashed_password, :type => String, :accessible => false
  field :first_name, :type => String
  field :last_name, :type => String
  field :email, :type => String
  field :crypt_strength, :type => Integer, :default => 4, :accessible => false
  field :organization, :type => String
  field :homepage, :type => String

  attr_accessor :password, :password_confirmation

  validates_uniqueness_of :login_name, :case_sensitive => false
  validates_length_of   :login_name,   :within => 3..40
  validates_format_of   :login_name,   :with => /\A([A-Z0-9.-]*)?\Z/i,
    :message => "may only contain letters, digits, hyphens and dots"
  
  validates_presence_of :first_name
  validates_presence_of :last_name
  
  validates_presence_of :email
  validates_format_of   :email,
    :with => /\A([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4})?\Z/i

  validates_format_of   :homepage,
    :with => /\A(http:\/\/[A-Z0-9.-]+\.[A-Z]{2,4}(\/[A-Z0-9.-~]*)*)?\Z/i

  validates_presence_of :password,                   :if => :password_required?
  validates_presence_of :password_confirmation,      :if => :password_given?
  validates_length_of   :password, :within => 6..40, :if => :password_given?
  validates_confirmation_of :password,               :if => :password_given?

  before_save :encrypt_password

  def self.authenticate(login_name, password)
    user = self.where(:login_name => login_name).first
    user if user and user.check_password(password)
  end
  
  def check_password(password)
    Crypt::check(password, hashed_password, :strength => crypt_strength)
  end
  
  def name
    if first_name.blank? or last_name.blank?
      login_name
    else
      [first_name, last_name].join(" ")
    end
  end
  
  def <=>(other)
    if other.is_a? User
      d = (self.last_name || "") <=> (other.last_name || "")
      if d == 0 then self.name <=> other.name else d end
    end
  end

  protected
  
  def self.encrypted_password(password, strength)
    Crypt::crypt(password, :strength => strength)
  end
  
  def encrypt_password
    return if password.blank?
    self.hashed_password = User.encrypted_password(password, crypt_strength)
  end
  
  def password_required?
    hashed_password.blank?
  end
  
  def password_given?
    not password.blank?
  end
end
