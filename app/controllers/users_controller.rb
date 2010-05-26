class UsersController < ApplicationController
  before_authorization_filter :find_user, :except => [:index, :new, :create]

  permit :index
  permit :new, :create,         :if => :may_create_user
  permit :show, :edit, :update, :if => :is_current_user

  private

  def may_create_user
    bootstrapping? or current_user
  end

  def find_user
    @user = User.find(params[:id])
  end

  def is_current_user
    @user == current_user
  end

  public

  def index
    @users = User.order_by [[:last_name, :asc], [:first_name, :asc]]
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    in_bootstrap = bootstrapping?
    @user = User.new(params[:user])
    @user.login_name = params[:user][:login_name]

    if @user.save
      new_session(@user) if in_bootstrap
      redirect_to @user, :notice => 'User was successfully created.'
    else
      render :action => 'new', :alert => 'Could not create user.'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      redirect_to @user, :notice => 'User was successfully updated.'
    else
      render :action => 'edit', :alert => 'Could not update user.'
    end
  end

  def destroy
    @user.destroy

    redirect_to(users_url)
  end
end
