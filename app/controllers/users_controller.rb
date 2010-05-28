class UsersController < ApplicationController
  before_authorization_filter :find_user, :except => [:index, :new, :create]

  permit :index,         :if => :may_edit
  permit :new, :create,  :if => :may_create_user
  permit :show,          :if => :may_view_user
  permit :edit, :update, :if => :may_edit_user

  private

  def may_create_user
    may_authorize or bootstrapping?
  end

  def may_view_user
    may_edit or @user == current_user
  end

  def may_edit_user
    may_authorize or @user == current_user
  end

  def find_user
    @user = User.find(params[:id])
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
    @user = User.new(params[:user])
    @user.login_name = params[:user][:login_name]
    @user.abilities = User::ADMIN_TASKS if bootstrapping?

    on_bootstraps = bootstrapping?
    if @user.save
      new_session(@user) if on_bootstraps
      redirect_to @user, :notice => 'User was successfully created.'
    else
      render :action => 'new', :alert => 'Could not create user.'
    end
  end

  def edit
  end

  def update
    User::ABILITIES.each do |a|
      unless can_authorize?(@user, a)
        params[:user].delete(User.ability_getter(a))
      end
    end
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
