class CreateDataNodes < ActiveRecord::Migration
  def self.up
    create_table :data_nodes do |t|
      t.integer  :project_id
      t.integer  :producer_id

      t.string   :fingerprint
      t.string   :sample
      t.string   :name
      t.string   :data_type
      t.string   :identifier
      t.text     :messages
      t.string   :status
      t.boolean  :hidden
      t.string   :filename
      t.datetime :synchronized_at

      t.string   :domain_origin
      t.string   :domain_size
      t.string   :voxel_size
      t.string   :voxel_unit
    end
  end

  def self.down
    drop_table :data_nodes
  end
end
