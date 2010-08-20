class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :login_name
      t.string  :hashed_password
      t.string  :first_name
      t.string  :last_name
      t.string  :email
      t.integer :crypt_strength, :default => 4
      t.string  :organization
      t.string  :homepage
      t.string  :abilities, :default => 'login view'
      t.timestamps
      t.integer :created_by
      t.integer :updated_by
    end
  end

  def self.down
    drop_table :users
  end
end
