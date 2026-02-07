# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_07_123155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "blacklisted_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "jti"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["jti"], name: "index_blacklisted_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_blacklisted_tokens_on_user_id"
  end

  create_table "otp_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", default: "", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "phone_number", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["phone_number", "code"], name: "index_otp_codes_on_phone_number_and_code", unique: true
  end

  create_table "refresh_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crypted_token"
    t.datetime "exp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["crypted_token"], name: "index_refresh_tokens_on_crypted_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "admin_verification_status", default: 0, null: false
    t.string "cnic_hash"
    t.text "cnic_images_data"
    t.datetime "created_at", null: false
    t.string "full_name"
    t.integer "gender"
    t.string "phone_number", default: "", null: false
    t.text "profile_picture_data"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.text "verification_selfie_data"
    t.index ["cnic_hash"], name: "index_users_on_cnic_hash", unique: true, where: "(cnic_hash IS NOT NULL)"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  add_foreign_key "blacklisted_tokens", "users"
  add_foreign_key "refresh_tokens", "users"
end
