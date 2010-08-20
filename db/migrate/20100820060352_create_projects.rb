class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :name
      t.string :organization
      t.timestamps
      t.integer :created_by
      t.integer :updated_by
    end
  end

  def self.down
    drop_table :projects
  end
end
