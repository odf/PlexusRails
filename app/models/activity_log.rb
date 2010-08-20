class ActivityLog < ActiveRecord::Base
  #field :at, :type => Time
  #field :action

  belongs_to :user

  def add(at, action)
    update_attributes(:at => at, :action => action)
  end

  def last_time
    at
  end
end
