class ProjectsController < ApplicationController
  before_authorization_filter :find_project, :except => [:index, :new, :create]

  permit :index
  permit :new, :create,           :if => :may_edit
  permit :show                    do may_view(@project)   end
  permit :edit, :update, :destroy do may_manage(@project) end

  before_filter :only => :update, :if => :edit_cancelled? do
    redirect_to @project, :notice => 'Project update was cancelled.'
  end

  before_filter :only => :create, :if => :edit_cancelled? do
    redirect_to projects_url, :notice => 'Project creation was cancelled.'
  end

  helper_method :may_manage

  private

  def find_project
    @project = Project.find(params[:id])
  end


  public

  def index
    @projects = Project.order_by(:name).select { |p| may_view(p) }
  end

  def show
  end

  def new
    @project = Project.new
    @project.memberships.build(:user => current_user, :role => 'manager')
  end

  def edit
  end

  def create
    @project = Project.new(params[:project])
    @project.name = params[:project][:name]

    if @project.save
      redirect_to @project, :notice => 'Project was successfully  created.'
    else
      render :action => 'new', :alert => 'Could not create project.'
    end
  end

  def update
    if @project.update_attributes(params[:project])
      redirect_to @project, :notice => 'Project was successfully updated.'
    else
      render :action => 'edit', :alert => 'Could not update project.'
    end
  end

  def destroy
    @project.destroy
    redirect_to(projects_url)
  end
end
