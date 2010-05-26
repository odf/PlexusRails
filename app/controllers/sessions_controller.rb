class SessionsController < ApplicationController
  permit :new, :create, :if => :logged_out
  permit :destroy

  before_filter :if => :bootstrapping? do
    redirect_to new_user_url, :notice => 'Please create a first user account.'
  end
  before_filter :redirect_to_ssl, :except => :destroy

  private
  
  def redirect_to_ssl
    redirect_to :protocol => 'https://' unless request.ssl? or local_request?
  end

  public

  def new
    @user = User.new
  end
    
  def create
    values = params[:user]
    user = User.authenticate(values[:login_name], values[:password])
    if user
      new_session(user)
      redirect_to projects_url, :notice => "Welcome #{user.name}!"
    else
      redirect_to login_url, :alert => 'Invalid user or password'
    end
  end

  def destroy
    new_session
    redirect_to new_session_url, :notice => 'Logged out'
  end
end
