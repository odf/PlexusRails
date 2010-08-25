class ActivityLog < ActiveRecord::Base
  # t.integer  "user_id"
  # t.datetime "at"
  # t.string   "action"

  belongs_to :user

  def add(at, action)
    update_attributes(:at => at, :action => action)
  end

  def last_time
    at
  end
end
