class ProjectsController < ApplicationController
  before_authorization_filter :find_project, :except => [:index, :new, :create]

  permit :index
  permit :new, :create,           :if => :may_edit
  permit :show                    do may_view_project(@project)   end
  permit :edit, :update, :destroy do may_manage_project(@project) end

  helper_method :may_view_project, :may_manage_project

  private

  def find_project
    @project = Project.find(params[:id])
  end

  def may_view_project(project)
    may_view and project.can_be_viewed_by current_user
  end

  def may_manage_project(project)
    may_edit and project.can_be_managed_by current_user
  end

  public

  def index
    @projects = Project.all.select(&self.method(:may_view_project))
  end

  def show
  end

  def new
    @project = Project.new
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
