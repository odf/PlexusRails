module Timestamps
  include SessionInfo

  extend ActiveSupport::Concern
  included do
    #field :created_at, :type => Time
    #field :updated_at, :type => Time
    belongs_to :created_by, :class_name => 'User'
    belongs_to :updated_by, :class_name => 'User'

    set_callback :create, :before, :set_created_at
    set_callback :update, :before, :set_updated_at
  end

  def set_created_at
    if !created_at
      self.created_at = Time.now.utc 
      self.created_by = current_user
    end
  end
  
  def set_updated_at
    self.updated_at = Time.now.utc
    self.updated_by = current_user
  end
end
