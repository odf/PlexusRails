class CreateSamples < ActiveRecord::Migration
  def self.up
    create_table :samples do |t|
      t.integer :project_id
      t.string  :name
      t.string  :external_id
      t.timestamps
      t.integer :created_by_id
      t.integer :updated_by_id
    end
  end

  def self.down
    drop_table :samples
  end
end
