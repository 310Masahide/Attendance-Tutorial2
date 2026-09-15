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

ActiveRecord::Schema[7.1].define(version: 2026_09_10_090713) do
  create_table "attendance_correction_requests", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "attendance_id", null: false
    t.bigint "user_id", null: false
    t.bigint "approver_id", null: false
    t.datetime "requested_started_at"
    t.datetime "requested_finished_at"
    t.string "note"
    t.integer "status", default: 1, null: false
    t.boolean "applicant_confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_attendance_correction_requests_on_approver_id"
    t.index ["attendance_id"], name: "index_attendance_correction_requests_on_attendance_id", unique: true
    t.index ["user_id"], name: "index_attendance_correction_requests_on_user_id"
  end

  create_table "attendances", charset: "utf8mb4", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "overtime_requests", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "worked_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "finished_hour"
    t.integer "finished_minute"
    t.boolean "finishes_next_day", default: false, null: false
    t.string "content"
    t.bigint "approver_id"
    t.integer "status", default: 1, null: false
    t.boolean "applicant_confirmed", default: false, null: false
    t.index ["approver_id"], name: "index_overtime_requests_on_approver_id"
    t.index ["user_id", "worked_on"], name: "index_overtime_requests_on_user_id_and_worked_on", unique: true
    t.index ["user_id"], name: "index_overtime_requests_on_user_id"
  end

  create_table "users", charset: "utf8mb4", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "department"
    t.datetime "basic_time", precision: nil, default: "2026-08-18 23:00:00"
    t.datetime "work_time", precision: nil, default: "2026-08-18 22:30:00"
    t.boolean "supervisor", default: false
    t.time "designated_work_start_time", default: "2000-01-01 00:00:00", null: false
    t.time "designated_work_end_time", default: "2000-01-01 09:00:00", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "attendance_correction_requests", "attendances"
  add_foreign_key "attendance_correction_requests", "users"
  add_foreign_key "attendance_correction_requests", "users", column: "approver_id"
  add_foreign_key "attendances", "users"
  add_foreign_key "overtime_requests", "users"
  add_foreign_key "overtime_requests", "users", column: "approver_id"
end
