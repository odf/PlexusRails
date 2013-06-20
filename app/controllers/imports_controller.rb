class ImportsController < ApplicationController
  protect_from_forgery :except => [ :data_index, :create ]

  before_authorization_filter :find_resource, :only => [:index, :show, :new]
  before_authorization_filter :find_user,     :only => [:data_index, :create]
  before_authorization_filter :find_sample

  permit :index               do may_edit            end
  permit :show                do may_view(@import)   end
  permit :new                 do may_edit(@sample)   end
  permit :data_index, :create do legitimate_uploader end
  
  private

  def find_project
    pid = params[:project_id]
    @project = if pid
                 Project.where(:id => pid).first
               else
                 Project.where(:name => params[:project]).first
               end
  end

  def find_sample
    sid = params[:sample_id]
    if sid
      @sample = Sample.where(:id => sid).first
      @project = @sample && @sample.project
    else
      find_project
      @sample =
        @project && @project.samples.where(:name => params[:sample]).first
    end
  end

  public

  def index
    @imports = @sample.imports.select { |i| may_view i }
  end

  def show
  end
  
  def data_index
    respond_to do |format|
      format.json do
        render :json => {
          "Project" => @project && @project.name,
          "Sample"  => @sample && "#{@sample.external_id} (#{@sample.name})",
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
    [:data, :description, :time, :source_log].each do |key|
      params[:import][key] = params[key] if params[:import][key].blank?
    end

    if params[:result] == "Cancel"
      notice = "Data import cancelled."
      import_log = { 'Status' => 'Cancelled' }
    elsif params[:import][:data].blank?
      notice = "No data supplied on import."
      import_log = { 'Status' => 'Error', 'Message' => 'No data supplied.' }
    else
      create_sample_if_missing
      @import = @sample.imports.build(params[:import].merge({:user => @user}))

      notice = @import.save ? "Import successful." : "Import failed."
      import_log = @import.import_log
    end

    respond_to do |format|
      format.html { redirect_to @sample, :notice => notice }
      format.json { render :json => import_log }
    end
  end

  private

  def create_sample_if_missing
    return if @sample

    find_or_create_project
    @sample = @project.samples.where(:name => params[:sample]).first
    unless @sample
      @sample = @project.samples.build(:name => params[:sample])
      @sample.save!
    end
  end

  def find_or_create_project
    return if @project

    name = params[:project]
    @project = Project.where(:name => name).first
    unless @project
      manager = User.where(:login_name => params[:manager]).first || @user
      @project = Project.new
      @project.name = name
      @project.set_role(manager, 'manager')
      @project.save!
    end
  end
end
