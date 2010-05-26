class ProjectsController < ApplicationController
  permit :index
  permit :show, :new, :edit, :create, :update, :destroy, :if => :logged_in

  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
  end

  def new
    @project = Project.new
  end

  def edit
    @project = Project.find(params[:id])
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
    @project = Project.find(params[:id])

    if @project.update_attributes(params[:project])
      redirect_to @project, :notice => 'Project was successfully updated.'
    else
      render :action => 'edit', :alert => 'Could not update project.'
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    redirect_to(projects_url)
  end
end
