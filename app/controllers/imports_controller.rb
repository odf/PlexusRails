class ImportsController < ApplicationController
  before_authorization_filter :find_project
  before_authorization_filter :find_import, :only => :show
  before_authorization_filter :find_user,   :only => :create

  permit :index  do may_edit end
  permit :show   do may_view(@import) end
  permit :new    do may_edit(@project) end
  permit :create do may_edit end
  
  private

  def find_project
    @project = Project.where(:_id => params[:project_id]).first
  end

  def find_import
    @import = @project.imports.where(:_id => params[:id]).first
  end

  def find_user
    @user = current_user || authenticated_user
  end

  def authenticated_user
    if request.ssl? or Rails.env != 'production'
      User.authenticate(params[:user] || {})
    end
  end

  public

  def index
    @imports = @project.imports.select { |i| may_view i }
  end

  def show
  end
  
  def new
    @import = Import.new
  end
  
  def create
    [:data, :description, :time, :sample, :source_log].each do |key|
      params[:import][key] = params[key] if params[:import][key].blank?
    end

    if params[:result] == "Cancel" or params[:import][:data].blank?
      respond_to do |format|
        format.html { redirect_to @project, :notice => "Data import cancelled." }
        format.json { render :json => { 'Status' => 'Cancelled' } }
      end
      return
    end

    create_project_if_missing

    @import = @project.imports.build(params[:import])
    @import.user = @user

    flash[:notice] = @import.save ? "Import successful." : "Import failed."

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render :json => @import.import_log }
    end
  end

  private

  def create_project_if_missing
    unless @project
      manager = User.where(:login_name => params[:manager]).first || @user
      @project = Project.new
      @project.name = params[:project]
      @project.set_role(manager, 'manager')
      @project.save!
    end
  end
end
