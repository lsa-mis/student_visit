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

ActiveRecord::Schema[8.1].define(version: 2026_01_20_175200) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "affiliated_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["department_id", "position"], name: "index_affiliated_resources_on_department_id_and_position"
    t.index ["department_id"], name: "index_affiliated_resources_on_department_id"
  end

  create_table "answer_edits", force: :cascade do |t|
    t.integer "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.integer "edited_by_id", null: false
    t.text "previous_content"
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_answer_edits_on_answer_id"
    t.index ["edited_by_id"], name: "index_answer_edits_on_edited_by_id"
  end

  create_table "answers", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "program_id", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["program_id"], name: "index_answers_on_program_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
  end

  create_table "appointment_selections", force: :cascade do |t|
    t.string "action", null: false
    t.integer "appointment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["appointment_id", "user_id"], name: "index_appointment_selections_on_appointment_id_and_user_id"
    t.index ["appointment_id"], name: "index_appointment_selections_on_appointment_id"
    t.index ["user_id"], name: "index_appointment_selections_on_user_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_time", null: false
    t.integer "program_id", null: false
    t.datetime "start_time", null: false
    t.integer "student_id"
    t.datetime "updated_at", null: false
    t.integer "vip_id", null: false
    t.index ["program_id", "start_time"], name: "index_appointments_on_program_id_and_start_time"
    t.index ["program_id"], name: "index_appointments_on_program_id"
    t.index ["student_id"], name: "index_appointments_on_student_id"
    t.index ["vip_id", "start_time"], name: "index_appointments_on_vip_id_and_start_time"
    t.index ["vip_id"], name: "index_appointments_on_vip_id"
  end

  create_table "calendar_event_faculties", force: :cascade do |t|
    t.integer "calendar_event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vip_id", null: false
    t.index ["calendar_event_id", "vip_id"], name: "index_calendar_event_faculties_on_calendar_event_id_and_vip_id", unique: true
    t.index ["calendar_event_id"], name: "index_calendar_event_faculties_on_calendar_event_id"
    t.index ["vip_id"], name: "index_calendar_event_faculties_on_vip_id"
  end

  create_table "calendar_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_time", null: false
    t.boolean "mandatory", default: false, null: false
    t.integer "program_id", null: false
    t.datetime "start_time", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id", "start_time"], name: "index_calendar_events_on_program_id_and_start_time"
    t.index ["program_id"], name: "index_calendar_events_on_program_id"
  end

  create_table "department_admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "department_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["department_id"], name: "index_department_admins_on_department_id"
    t.index ["user_id", "department_id"], name: "index_department_admins_on_user_id_and_department_id", unique: true
    t.index ["user_id"], name: "index_department_admins_on_user_id"
  end

  create_table "departments", force: :cascade do |t|
    t.integer "active_program_id"
    t.string "building_name"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "main_office_phone_number"
    t.string "main_office_room_number"
    t.text "mission_statement"
    t.string "name", null: false
    t.string "state"
    t.string "street_address"
    t.datetime "updated_at", null: false
    t.string "zipcode"
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "important_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "program_id", null: false
    t.integer "ranking", default: 0
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["program_id", "ranking"], name: "index_important_links_on_program_id_and_ranking"
    t.index ["program_id"], name: "index_important_links_on_program_id"
  end

  create_table "page_contents", force: :cascade do |t|
    t.string "area_name", null: false
    t.datetime "created_at", null: false
    t.string "page_path", null: false
    t.datetime "updated_at", null: false
    t.index ["page_path", "area_name"], name: "index_page_contents_on_page_and_area", unique: true
  end

  create_table "programs", force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "close_date"
    t.datetime "created_at", null: false
    t.integer "default_appointment_length", default: 30
    t.integer "department_id", null: false
    t.text "google_map_url"
    t.json "held_on_dates"
    t.string "information_email_address"
    t.string "name", null: false
    t.datetime "open_date"
    t.datetime "questionnaire_due_date"
    t.datetime "updated_at", null: false
    t.index ["department_id", "active"], name: "index_programs_on_department_id_and_active"
    t.index ["department_id"], name: "index_programs_on_department_id"
  end

  create_table "questionnaires", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "program_id", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_questionnaires_on_program_id"
  end

  create_table "questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "options"
    t.integer "position"
    t.string "question_type"
    t.integer "questionnaire_id", null: false
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["questionnaire_id"], name: "index_questions_on_questionnaire_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", limit: 4, null: false
    t.datetime "created_at", null: false
    t.binary "key", limit: 1024, null: false
    t.integer "key_hash", limit: 8, null: false
    t.binary "value", limit: 536870912, null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "student_programs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "program_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["program_id"], name: "index_student_programs_on_program_id"
    t.index ["user_id", "program_id"], name: "index_student_programs_on_user_id_and_program_id", unique: true
    t.index ["user_id"], name: "index_student_programs_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "must_change_password"
    t.string "password_digest", null: false
    t.string "umid"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["umid"], name: "index_users_on_umid", unique: true
  end

  create_table "vips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "display_on_student_dashboard", default: false, null: false
    t.string "name", null: false
    t.string "profile_url"
    t.integer "program_id", null: false
    t.integer "ranking", default: 0
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["program_id", "ranking"], name: "index_vips_on_program_id_and_ranking"
    t.index ["program_id"], name: "index_vips_on_program_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "affiliated_resources", "departments"
  add_foreign_key "answer_edits", "answers"
  add_foreign_key "answer_edits", "users", column: "edited_by_id"
  add_foreign_key "answers", "programs"
  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "users"
  add_foreign_key "appointment_selections", "appointments"
  add_foreign_key "appointment_selections", "users"
  add_foreign_key "appointments", "programs"
  add_foreign_key "appointments", "users", column: "student_id"
  add_foreign_key "appointments", "vips"
  add_foreign_key "calendar_event_faculties", "calendar_events"
  add_foreign_key "calendar_event_faculties", "vips"
  add_foreign_key "calendar_events", "programs"
  add_foreign_key "department_admins", "departments"
  add_foreign_key "department_admins", "users"
  add_foreign_key "departments", "programs", column: "active_program_id", on_delete: :nullify
  add_foreign_key "important_links", "programs"
  add_foreign_key "programs", "departments"
  add_foreign_key "questionnaires", "programs"
  add_foreign_key "questions", "questionnaires"
  add_foreign_key "sessions", "users"
  add_foreign_key "student_programs", "programs"
  add_foreign_key "student_programs", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "vips", "programs"
end
