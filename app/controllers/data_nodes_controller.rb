class DataNodesController < ApplicationController
  before_authorization_filter :find_resource
  before_authorization_filter :find_project

  permit :show do may_view(@data_node) end
  permit :toggle do may_edit(@project) end

  before_filter :prepare_tabs

  private

  def find_project
    @project = @data_node.project
  end

  def prepare_tabs
    #session['active-tab'] = params['active-tab'] if params['active-tab']
    #@active_tab = session['active-tab'] || "#general"
    @active_tab = '#general'
  end

  public

  def show
  end

  def toggle
    @data_node.toggle_visibility
    render :action => :show
  end
end
