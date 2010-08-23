class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string  :filename
      t.string  :stored_path
      t.string  :content_type
      t.integer :size
      t.integer :width
      t.integer :height
      t.string  :caption
      t.text    :info
      t.integer :illustratable_id
      t.string  :illustratable_type
      t.timestamps
      t.integer :created_by_id
      t.integer :updated_by_id
    end
  end

  def self.down
    drop_table :images
  end
end
