class ApplicationController < ActionController::Base
  protect_from_forgery

  layout 'application'

  # -- make general helper methods available
  include ApplicationHelper

  # -- methods that will be accessible to templates
  helper_method(:current_date, :current_time, :current_user, :can_authorize?,
                *User::ABILITIES.map(&User.method(:ability_getter)))

  # -- we need to make some session info available to models
  before_filter :store_info

  # -- log a user's activity
  before_filter :log_activity

  # -- this handles session expiration, invalid IP addresses, etc.
  around_filter :validate_session

  # -- manage authorization via the 'verboten' gem
  forbid_everything
  
  # -- define methods for inquiring the permissions of the current user
  def method_missing(name, *args)
    if name.to_s.starts_with?('may_')
      resource = args[0]
      if resource.respond_to?(:allows?)
        resource.send(:allows?, name.to_s.sub(/may_/, '').to_sym, current_user)
      elsif current_user.respond_to?(name)
        current_user.send(name)
      end
    else
      super
    end
  end

  def respond_to?(name)
    name.to_s.starts_with?('may_') or super
  end

  # Checks whether the given user can authorize the given ability.
  def can_authorize?(user, a)
    current_user and current_user.can_authorize?(user, a)
  end

  # Returns the current date as a nicely formatted string
  def current_date
    format_date(Date.today)
  end

  # Returns the current date as a nicely formatted string
  def current_time
    format_time(Time.now)
  end

  # The logged in user for the current session, or nil if none.
  def current_user
    User.where(:login_name => session[:user]).first
  end

  private

  def find_user
    @user = current_user || authenticated_user
  end

  def authenticated_user
    if request.ssl? or not Rails.env.production?
      User.authenticate(params[:user] || {})
    end
  end

  def legitimate_user
    if @project
      @project.allows?(:upload, @user)
    else
      @user and @user.may_upload
    end
  end

  # Creates instance variables for a resource and, if nested, its ancestors.
  def find_resource(options = {})
    found = find_recursively(self.class.name.sub(/Controller$/, ''), 0, options)
    variable = "@#{options[:as] || found.class.name.underscore}"
    instance_variable_set(variable, found)
  end

  def find_recursively(class_name, level = 0, options = {})
    model_class = class_name.classify.constantize
    key = level == 0 ? "id" : "#{class_name.underscore}_id"
    assoc = if level == 0 and params[:nested_in]
              make_assoc(params[:nested_in], class_name)
            elsif model_class.embedded?
              model_class.associations.values.find do |v|
                v.association == Mongoid::Associations::EmbeddedIn
              end
            end
    if assoc
      parent = find_recursively(assoc.name, level + 1)
      instance_variable_set("@#{options[:parent_as] || assoc.name}", parent)
      parent.send(assoc.inverse_of).find(params[key])
    else
      model_class.find(params[key])
    end
  end

  def make_assoc(name, inverse)
    Struct.new('Assoc', 'name', 'inverse_of') unless defined?(Struct::Assoc)
    Struct::Assoc.new(name.underscore, inverse.underscore)
  end

  # A unified way to abort an action if the 'Cancel' button was pressed.
  def self.redirect_if_cancelled
    before_filter :only => :update do
      if params[:result] == 'Cancel'
        flash[:notice] = 'Update was cancelled.'
        redirect_to :action => :show
      end
    end

    before_filter :only => :create do
      if params[:result] == 'Cancel'
        flash[:notice] = 'Creation was cancelled.'
        redirect_to :action => :index
      end
    end
  end

  # Starts a new session in which the given user is logged in.
  def new_session(user = nil)
    reset_session
    session[:user] = user && user.login_name
    session[:ip] = request.remote_ip
  end

  # If this returns true, we have a new installation that needs setup.
  def bootstrapping?
    User.count == 0
  end

  # Returns true if the request is from localhost.
  def local_request?
    request.remote_ip == '127.0.0.1'
  end

  # This stores some session info so that models can access it.
  def store_info
    SessionInfo.current_user = current_user
    SessionInfo.request_host = request.host_with_port
  end

  # Update the current user's activity log
  def log_activity
    current_user.log_activity(Time.now.utc) if current_user
  end

  # This is called as an around filter for all controller actions and
  # handles session expiration, invalid IP addresses, etc.
  def validate_session
    # -- if someone is logged in, make sure the session is still valid
    error = current_user && check_session

    if error
      # -- close the current session and report the error
      new_session
      flash.now[:error] = error
      render :text => '', :layout => true
    else
      # -- no error: call the intended controller action
      yield
    end

    # -- the session will expire after an hour of inactivity
    session[:expires_at] = 1.hour.since
  end

  # Performs some tests to see if a login session is still valid.
  def check_session
    if request.remote_ip != session[:ip]
      'Your network connection seems to have changed.'
    elsif !session[:expires_at] or session[:expires_at] < Time.now
      'Your session has expired.'
    end
  rescue ActiveRecord::RecordNotFound
    'You seem to have a stale session cookie.'
  end
end
