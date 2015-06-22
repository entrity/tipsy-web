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

ActiveRecord::Schema.define(version: 20150622015213) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "dblink"

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "text"
    t.integer  "flag_pts",         limit: 2, default: 0
    t.integer  "flagger_ids",                default: [], array: true
    t.integer  "status",           limit: 2, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "drinks", force: :cascade do |t|
    t.string  "name"
    t.integer "abv",           limit: 2
    t.text    "description"
    t.text    "text"
    t.float   "score"
    t.integer "vote_ct",                  default: 0
    t.integer "glass_id",      limit: 2
    t.string  "color",         limit: 16
    t.integer "comment_ct",               default: 0
    t.integer "ingredient_ct",            default: 0
    t.boolean "profane",                  default: false
    t.boolean "non_alcoholic",            default: false
    t.integer "flagger_ids",              default: [],    array: true
    t.integer "flag_pts",      limit: 2,  default: 0
    t.integer "revision_id"
  end

  add_index "drinks", ["name"], name: "index_drinks_on_name", using: :btree

  create_table "drinks_ingredients", id: false, force: :cascade do |t|
    t.integer "drink_id"
    t.integer "ingredient_id"
    t.string  "qty"
  end

  add_index "drinks_ingredients", ["drink_id"], name: "index_drinks_ingredients_on_drink_id", using: :btree
  add_index "drinks_ingredients", ["ingredient_id"], name: "index_drinks_ingredients_on_ingredient_id", using: :btree

  create_table "flags", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "flaggable_id"
    t.string   "flaggable_type"
    t.integer  "points",         limit: 2, null: false
    t.datetime "created_at"
  end

  create_table "identities", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ingredients", force: :cascade do |t|
    t.string  "name"
    t.text    "text"
    t.integer "flagger_ids",           default: [], array: true
    t.integer "flag_pts",    limit: 2, default: 0
    t.integer "revision_id"
  end

  add_index "ingredients", ["name"], name: "index_ingredients_on_name", using: :btree

  create_table "review_votes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "review_id"
    t.integer  "points",     limit: 2, null: false
    t.datetime "created_at"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer  "reviewable_id"
    t.string   "reviewable_type"
    t.boolean  "open",                      default: true
    t.integer  "points",          limit: 2, default: 0
    t.datetime "created_at"
  end

  add_index "reviews", ["reviewable_id", "reviewable_type"], name: "index_reviews_on_reviewable_id_and_reviewable_type", using: :btree

  create_table "revisions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "flaggable_id"
    t.string   "flaggable_type"
    t.text     "text"
    t.integer  "flag_pts",       limit: 2, default: 0
    t.integer  "flagger_ids",              default: [], array: true
    t.integer  "status",         limit: 2, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "revisions", ["flaggable_id", "flaggable_type"], name: "index_revisions_on_flaggable_id_and_flaggable_type", using: :btree
  add_index "revisions", ["user_id"], name: "index_revisions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "name"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "no_alcohol",             default: false
    t.boolean  "no_profanity",           default: false
    t.integer  "helpful_flags",          default: 0
    t.integer  "unhelpful_flags",        default: 0
    t.integer  "majority_review_votes",  default: 0
    t.integer  "minority_review_votes",  default: 0
    t.integer  "points",                 default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
