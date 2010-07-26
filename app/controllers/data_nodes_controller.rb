class DataNodesController < ApplicationController
  before_authorization_filter :find_project
  before_authorization_filter :find_node

  permit :show do may_view(@data_node) end
  permit :toggle do may_edit(@project) end

  private

  def find_project
    @project = Project.where(:_id => params[:project_id]).first
  end

  def find_node
    @data_node = @project.data_nodes.where(:_id => params[:id]).first
  end

  public

  def show
  end

  def toggle
    @data_node.toggle_visibility
    render :action => :show
  end
end
