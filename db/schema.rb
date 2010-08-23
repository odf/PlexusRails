# This file is auto-generated from the current state of the database. Instead 
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your 
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100823060432) do

  create_table "activity_logs", :force => true do |t|
    t.integer  "user_id"
    t.datetime "at"
    t.string   "action"
  end

  create_table "comments", :force => true do |t|
    t.text     "text"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  create_table "data_nodes", :force => true do |t|
    t.integer  "project_id"
    t.integer  "producer_id"
    t.string   "fingerprint"
    t.string   "sample"
    t.string   "name"
    t.string   "data_type"
    t.string   "identifier"
    t.text     "messages"
    t.string   "status"
    t.boolean  "hidden"
    t.string   "filename"
    t.datetime "synchronized_at"
    t.string   "domain_origin"
    t.string   "domain_size"
    t.string   "voxel_size"
  end

  create_table "images", :force => true do |t|
    t.string   "filename"
    t.string   "stored_path"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.string   "caption"
    t.text     "info"
    t.integer  "illustratable_id"
    t.string   "illustratable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  create_table "imports", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.datetime "source_timestamp"
    t.string   "sample_name"
    t.text     "content"
    t.text     "source_log"
    t.text     "import_log"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  create_table "memberships", :force => true do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.string  "role"
  end

  create_table "process_nodes", :force => true do |t|
    t.datetime "date"
    t.string   "run_by"
    t.string   "data_type"
    t.text     "history"
    t.text     "output_log"
    t.text     "parameters"
    t.text     "input_ids"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "organization"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  create_table "users", :force => true do |t|
    t.string   "login_name"
    t.string   "hashed_password"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "crypt_strength",  :default => 4
    t.string   "organization"
    t.string   "homepage"
    t.string   "abilities",       :default => "login view"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

end
