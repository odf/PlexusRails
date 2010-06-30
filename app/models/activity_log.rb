class ActivityLog
  include Mongoid::Document

  field :at, :type => Time
  field :action, :type => String

  references_one :user

  def add(at, action)
    update_attributes(:at => at, :action => action)
  end

  def last_time
    at
  end
end
