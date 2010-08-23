class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.text    :text
      t.integer :commentable_id
      t.string  :commentable_type
      t.timestamps
      t.integer  :created_by_id
      t.integer  :updated_by_id
    end
  end

  def self.down
    drop_table :comments
  end
end
