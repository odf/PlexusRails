class CreateActivityLog < ActiveRecord::Migration
  def self.up
    create_table :activity_logs do |t|
      t.integer  :user_id
      t.datetime :at
      t.string   :action
    end
  end

  def self.down
    drop_table :activity_logs
  end
end
