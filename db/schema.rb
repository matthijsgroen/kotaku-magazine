# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100602081742) do

  create_table "issue_pages", :force => true do |t|
    t.integer  "issue_id"
    t.integer  "article_nr"
    t.text     "html_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url"
    t.string   "classification"
    t.string   "title"
  end

  create_table "magazines", :force => true do |t|
    t.string   "url"
    t.string   "filename"
    t.string   "issue_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end