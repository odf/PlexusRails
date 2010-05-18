class UsersController < ApplicationController
  before_authorization_filter :find_user, :except => [:index, :new, :create]

  permit :index
  permit :new, :create,         :if => :logged_in
  permit :show, :edit, :update, :if => :is_current_user

  private

  def find_user
    @user = User.find(params[:id])
  end

  def is_current_user
    @user == current_user
  end

  public

  def index
    @users = User.all.sort
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])

    if @user.save
      redirect_to(@user, :notice => 'User was successfully created.')
    else
      flash.now[:error] =  'Could not create user.'
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      redirect_to(@user, :notice => 'User was successfully updated.')
    else
      flash.now[:error] =  'Could not update user.'
      render :action => "edit"
    end
  end

  def destroy
    @user.destroy

    redirect_to(users_url)
  end
end
