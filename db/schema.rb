# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130713150547) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: true do |t|
    t.integer  "blog_id"
    t.text     "title"
    t.text     "body"
    t.integer  "markup_syntax_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "articles", ["created_at"], name: "index_articles_on_created_at", using: :btree

  create_table "blogs", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "markup_syntax_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "markup_syntaxes", force: true do |t|
    t.text     "name"
    t.text     "class_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.text     "name"
    t.text     "profile"
    t.text     "email"
    t.text     "password_digest"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
