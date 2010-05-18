class ApplicationController < ActionController::Base
  protect_from_forgery

  layout 'application'

  # -- methods that will be accessible to templates
  helper_method :current_date, :current_time, :current_user

  # -- this handles session expiration, invalid IP addresses, etc.
  around_filter :validate_session

  # -- manage authorization via the 'verboten' gem
  forbid_everything
  
  private

  # Returns the current date as a nicely formatted string
  def current_date
    Date.today.strftime("%d %B %Y")
  end

  # Returns the current date as a nicely formatted string
  def current_time
    Time.now.strftime("%d-%B-%Y %H:%M:%S")
  end

  # The logged in user for the current session, or nil if none.
  def current_user
    User.where(:login_name => session[:user]).first
  end

  # Starts a new session in which the given user is logged in.
  def new_session(user = nil)
    reset_session
    session[:user] = user && user.login_name
    session[:ip] = request.remote_ip
  end

  # This is called as an around filter for all controller actions and
  # handles session expiration, invalid IP addresses, etc.
  def validate_session
    if current_user
      # -- if someone is logged in, check some things
      begin
        SessionInfo.current_user = current_user
        SessionInfo.request_host = request.host_with_port
        # -- terminate session if expired or the IP address has changed
        if request.remote_ip != session[:ip]
          error = "Your network connection seems to have changed."
        elsif !session[:expires_at] or session[:expires_at] < Time.now
          error = "Your session has expired."
        end
      rescue ActiveRecord::RecordNotFound
        # -- handle stale session cookies
        error = "You seem to have a stale session cookie."
      end
    end

    # -- report an error or call the controller action
    if error
      new_session
      flash.now['error'] = error
      render :text => '', :layout => true
    else
      yield
    end

    # -- make session expire after an hour of inactivity
    session[:expires_at] = 1.hour.since
  end
end
