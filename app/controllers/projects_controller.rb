class ProjectsController < ApplicationController
  before_authorization_filter :find_resource, :except => [:index, :new, :create]

  permit :index
  permit :new, :create,           :if => :may_edit
  permit :show                    do may_view(@project)   end
  permit :edit, :update, :destroy do may_manage(@project) end

  helper_method :may_manage


  def index
    @projects = Project.order(:name).select { |p| may_view(p) }
  end

  def show
  end

  def new
    @project = Project.new
    @project._manager = current_user
  end

  def edit
  end

  def create
    if params[:result] == 'Cancel'
      flash[:notice] = 'Creation was cancelled.'
      redirect_to :action => :index
    else
      @project = Project.new(params[:project])
      @project.name = params[:project][:name]

      if @project.save
        redirect_to @project, :notice => 'Project was successfully  created.'
      else
        render :action => 'new', :alert => 'Could not create project.'
      end
    end
  end

  def update
    if params[:result] == 'Cancel'
      flash[:notice] = 'Update was cancelled.'
    elsif @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated.'
    else
      render :action => 'edit', :alert => 'Could not update project.'
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, :notice => 'Project successfully deleted.'
  end
end
