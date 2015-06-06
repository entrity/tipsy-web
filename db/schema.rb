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

ActiveRecord::Schema.define(version: 20150525005011) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "dblink"

  create_table "drinks", force: :cascade do |t|
    t.string  "name"
    t.integer "abv",          limit: 2
    t.text    "description"
    t.text    "instructions"
    t.float   "score"
    t.integer "vote_ct"
    t.integer "glass_id",     limit: 2
    t.string  "color",        limit: 16
  end

  add_index "drinks", ["name"], name: "index_drinks_on_name", using: :btree

  create_table "drinks_ingredients", id: false, force: :cascade do |t|
    t.integer "drink_id"
    t.integer "ingredient_id"
    t.string  "qty"
  end

  add_index "drinks_ingredients", ["drink_id"], name: "index_drinks_ingredients_on_drink_id", using: :btree
  add_index "drinks_ingredients", ["ingredient_id"], name: "index_drinks_ingredients_on_ingredient_id", using: :btree

  create_table "ingredients", force: :cascade do |t|
    t.string "name"
    t.text   "description"
  end

  add_index "ingredients", ["name"], name: "index_ingredients_on_name", using: :btree

end
