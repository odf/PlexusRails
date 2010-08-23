class CreateProcessNodes < ActiveRecord::Migration
  def self.up
    create_table :process_nodes do |t|
      t.integer  :project_id
      t.datetime :date
      t.string   :run_by
      t.string   :data_type
      t.text     :history
      t.text     :output_log
      t.text     :parameters
      t.text     :input_ids
    end
  end

  def self.down
    drop_table :process_nodes
  end
end
