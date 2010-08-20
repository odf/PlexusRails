class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name
      t.string :organization
      t.timestamps
      t.integer :created_by_id
      t.integer :updated_by_id
    end
  end

  def self.down
    drop_table :projects
  end
end
