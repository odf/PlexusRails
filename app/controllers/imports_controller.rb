class ImportsController < ApplicationController
  protect_from_forgery :except => [ :data_index, :create ]

  before_authorization_filter :find_resource
  before_authorization_filter :find_user, :only => [:data_index, :create]

  permit :index               do may_edit           end
  permit :show                do may_view(@import)  end
  permit :new                 do may_edit(@project) end
  permit :data_index, :create do legitimate_user    end
  
  private

  def find_user
    @user = current_user || authenticated_user
  end

  def authenticated_user
    if request.ssl? or not Rails.env.production?
      User.authenticate(params[:user] || {})
    end
  end

  def legitimate_user
    if @project
      @project.allows?(:upload, @user)
    else
      @user and @user.may_upload
    end
  end

  public

  def index
    @imports = @project.imports.select { |i| may_view i }
  end

  def show
  end
  
  def data_index
    respond_to do |format|
      format.json do
        render :json => {
          "Project" => @project && @project.name,
          "Sample"  => @sample && "#{@sample.name} (#{@sample.nickname})",
          "Nodes"   => @sample ? @sample.stored_data : [],
          "Status"  => "Success"
        }
      end
    end
  end

  def new
    @import = Import.new
  end
  
  def create
    params[:import] ||= {}
    [:data, :description, :time, :sample, :source_log].each do |key|
      params[:import][key] = params[key] if params[:import][key].blank?
    end

    if params[:result] == "Cancel"
      notice = "Data import cancelled."
      import_log = { 'Status' => 'Cancelled' }
    elsif params[:import][:data].blank?
      notice = "No data supplied on import."
      import_log = { 'Status' => 'Error', 'Message' => 'No data supplied.' }
    else
      create_project_if_missing

      @import = @project.imports.build(params[:import])
      @import.user = @user

      notice = @import.save ? "Import successful." : "Import failed."
      import_log = @import.import_log
    end

    respond_to do |format|
      format.html { redirect_to @project || projects_url, :notice => notice }
      format.json { render :json => import_log }
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
