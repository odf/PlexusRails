class DataNodesController < ApplicationController
  before_authorization_filter :find_resource
  before_authorization_filter :find_sample

  permit :show do may_view(@data_node) end
  permit :toggle do may_edit(@sample) end

  before_filter :prepare_tabs

  private

  def find_sample
    @sample = @data_node.sample
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
