module Blame
  include SessionInfo

  def self.included(base)
    base.class_eval do
      belongs_to :created_by, :class_name => 'User'
      belongs_to :updated_by, :class_name => 'User'

      before_create do |item| item.created_by = current_user end
      before_save   do |item| item.updated_by = current_user end
    end
  end
end
