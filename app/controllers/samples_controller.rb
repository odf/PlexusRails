class SamplesController < ApplicationController
  before_authorization_filter :find_resource, :except => [:index, :new, :create]
  before_authorization_filter :find_project

  permit :index
  permit :new, :create, :destroy do may_edit(@project) end
  permit :show                   do may_view(@sample)  end
  permit :edit, :update          do may_edit(@sample)  end

  private

  def find_project
    @project = if @sample
                 @sample.project
               else
                 Project.where(:id => params[:project_id]).first
               end
  end

  public

  def index
    @samples = Sample.order(:name).select { |s| may_view(s) }
  end

  def show
  end

  def new
    @sample = @project.samples.build
  end

  def edit
  end

  def create
    if params[:result] == 'Cancel'
      flash[:notice] = 'Creation was cancelled.'
      redirect_to :action => :index
    else
      @sample = @project.samples.build(params[:sample])

      if @sample.save
        redirect_to @sample, :notice => 'Sample was successfully  created.'
      else
        render :action => 'new', :alert => 'Could not create sample.'
      end
    end
  end

  def update
    if params[:result] == 'Cancel'
      flash[:notice] = 'Update was cancelled.'
    elsif @sample.update_attributes(params[:sample])
      flash[:notice] = 'Sample was successfully updated.'
    else
      render :action => 'edit', :alert => 'Could not update sample.'
    end
  end

  def destroy
    @sample.destroy
    redirect_to @project, :notice => 'Sample successfully deleted.'
  end
end
