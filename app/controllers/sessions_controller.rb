class SessionsController < ApplicationController
  permit :new, :create, :if => :logged_out
  permit :destroy

  before_filter :new_session
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
    user = User.authenticate(values[:name], values[:password])
    if user
      new_session(user)
      flash[:notice] = "Welcome #{user.name}!"
      redirect_to projects_url
    else
      flash[:error] = "Invalid user or password"
      redirect_to new_session_url
    end
  end

  def destroy
    flash[:notice] = "Logged out"
    redirect_to new_session_url
  end
end
