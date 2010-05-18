class SessionsController < ApplicationController
  def new
    new_session
    
    unless request.ssl? or Rails.env != 'production'
      redirect_to new_session_url.sub(/^http:/, 'https:')
    end
    
    @user = User.new
  end
    
  def create
    new_session

    unless request.ssl? or Rails.env != 'production'
      redirect_to new_session_url.sub(/^http:/, 'https:')
    end
    
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
    new_session
    flash[:notice] = "Logged out"
    redirect_to new_session_url
  end
end
