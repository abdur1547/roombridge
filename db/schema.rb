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

ActiveRecord::Schema[8.1].define(version: 2026_02_08_000001) do
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

  create_table "listings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "area", null: false
    t.date "available_from", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.integer "deposit"
    t.boolean "furnished", default: false, null: false
    t.integer "gender_preference", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "max_occupants", null: false
    t.integer "minimum_stay_months", default: 1, null: false
    t.text "photos_data"
    t.integer "rent_monthly", null: false
    t.integer "room_type", null: false
    t.boolean "smoking_allowed", default: false, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["city", "area"], name: "index_listings_on_city_and_area"
    t.index ["is_active"], name: "index_listings_on_is_active"
    t.index ["user_id"], name: "index_listings_on_user_id"
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
  add_foreign_key "listings", "users", on_delete: :cascade
  add_foreign_key "refresh_tokens", "users"
end
