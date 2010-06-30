class ImportsController < ApplicationController
  before_authorization_filter :find_resource, :only => :show
  before_authorization_filter :find_project
  before_authorization_filter :find_user,     :only => :create

  permit :index  do may_edit end
  permit :show   do may_view(@import) end
  permit :new    do may_edit(@project) end
  permit :create do may_edit end
  
  private

  def find_project
    @project = Project.where(:_id => params[:project_id]).first
  end

  def find_user
    @user = current_user ||
      if request.ssl? or ENV['RAILS_ENV'] != 'production'
        name   = params[:user] && params[:user][:name]
        passwd = params[:user] && params[:user][:password]
        User.authenticate(name, passwd)
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
    params.merge!(params[:import] || {})

    if params[:result] == "Cancel" or params[:data].blank?
      respond_to do |format|
        format.html { redirect_to @project, :notice => "Data import cancelled." }
        format.json { render :json => { 'Status' => 'Cancelled' } }
      end
      return
    end

    unless @project
      manager = User.where(:login_name => params[:manager]).first || @user
      @project = Project.new
      @project.name = params[:project]
      @project.set_role(manager, 'manager')
      @project.save!
    end

    replace = params[:replace] == "True"
    
    time_args = ParseDate::parsedate(params[:time]) unless params[:time].blank?
    time = (time_args ? Time.local(*time_args) : Time.now).getutc
    
    attached = params[:data].read

    @import = @project.imports.create!(:sample_name => params[:sample],
                                       :user_id => @user.id,
                                       :source_timestamp => time,
                                       :replace => replace,
                                       :content => attached,
                                       :description => params[:description])
                                     
    respond_to do |format|
      format.html { redirect_to @project, :notice => "Data import successful." }
      format.json { render :json => @import.import_log }
    end
  end
end
