class CreateImports < ActiveRecord::Migration
  def self.up
    create_table :imports do |t|
      t.integer  :user_id
      t.integer  :project_id
      t.datetime :source_timestamp
      t.string   :sample_name
      t.text     :content
      t.text     :source_log
      t.text     :import_log
      t.string   :description
    end
  end

  def self.down
    drop_table :imports
  end
end
