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

ActiveRecord::Schema.define(version: 20160923160338) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "affairs", force: :cascade do |t|
    t.integer  "owner_id",                                    null: false
    t.integer  "buyer_id",                                    null: false
    t.integer  "receiver_id",                                 null: false
    t.string   "title",           limit: 255, default: "",    null: false
    t.text     "description",                 default: ""
    t.bigint   "value_in_cents",              default: 0,     null: false
    t.string   "value_currency",  limit: 255, default: "CHF", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                      default: 0,     null: false
    t.boolean  "estimate",                    default: false, null: false
    t.integer  "parent_id"
    t.text     "footer"
    t.text     "conditions"
    t.integer  "seller_id",                   default: 1,     null: false
    t.integer  "condition_id"
    t.boolean  "unbillable",                  default: false, null: false
    t.text     "notes"
    t.float    "vat_percentage"
    t.integer  "vat_in_cents",                default: 0,     null: false
    t.string   "vat_currency",    limit: 255, default: "CHF", null: false
    t.string   "alias_name",      limit: 255
    t.text     "execution_notes"
    t.boolean  "archive",                     default: false, null: false
    t.datetime "sold_at"
    t.index ["alias_name"], name: "index_affairs_on_alias_name", using: :btree
    t.index ["archive"], name: "index_affairs_on_archive", using: :btree
    t.index ["buyer_id"], name: "index_affairs_on_buyer_id", using: :btree
    t.index ["condition_id"], name: "index_affairs_on_condition_id", using: :btree
    t.index ["created_at"], name: "index_affairs_on_created_at", using: :btree
    t.index ["estimate"], name: "index_affairs_on_estimate", using: :btree
    t.index ["owner_id"], name: "index_affairs_on_owner_id", using: :btree
    t.index ["parent_id"], name: "index_affairs_on_parent_id", using: :btree
    t.index ["receiver_id"], name: "index_affairs_on_receiver_id", using: :btree
    t.index ["seller_id"], name: "index_affairs_on_seller_id", using: :btree
    t.index ["sold_at"], name: "index_affairs_on_sold_at", using: :btree
    t.index ["status"], name: "index_affairs_on_status", using: :btree
    t.index ["updated_at"], name: "index_affairs_on_updated_at", using: :btree
    t.index ["value_currency"], name: "index_affairs_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_affairs_on_value_in_cents", using: :btree
    t.index ["vat_currency"], name: "index_affairs_on_vat_currency", using: :btree
    t.index ["vat_in_cents"], name: "index_affairs_on_vat_in_cents", using: :btree
    t.index ["vat_percentage"], name: "index_affairs_on_vat_percentage", using: :btree
  end

  create_table "affairs_conditions", force: :cascade do |t|
    t.string  "title",       limit: 255
    t.text    "description"
    t.boolean "archive",                 default: false, null: false
  end

  create_table "affairs_products_categories", force: :cascade do |t|
    t.integer "affair_id",             null: false
    t.string  "title",     limit: 255
    t.integer "position",              null: false
    t.index ["affair_id"], name: "index_affairs_products_categories_on_affair_id", using: :btree
    t.index ["position"], name: "index_affairs_products_categories_on_position", using: :btree
  end

  create_table "affairs_stakeholders", force: :cascade do |t|
    t.integer "person_id"
    t.integer "affair_id"
    t.string  "title",     limit: 255
    t.index ["affair_id"], name: "index_affairs_stakeholders_on_affair_id", using: :btree
    t.index ["person_id"], name: "index_affairs_stakeholders_on_person_id", using: :btree
  end

  create_table "affairs_subscriptions", id: false, force: :cascade do |t|
    t.integer "affair_id"
    t.integer "subscription_id"
    t.index ["affair_id"], name: "index_affairs_subscriptions_on_affair_id", using: :btree
    t.index ["subscription_id"], name: "index_affairs_subscriptions_on_subscription_id", using: :btree
  end

  create_table "application_settings", force: :cascade do |t|
    t.string "key",                 limit: 255, default: ""
    t.text   "value",                           default: ""
    t.string "type_for_validation", limit: 255, default: "string", null: false
    t.index ["key"], name: "index_application_settings_on_key", using: :btree
  end

  create_table "background_tasks", force: :cascade do |t|
    t.string   "type",        limit: 255
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",       limit: 255
    t.integer  "person_id"
    t.string   "ui_trigger",  limit: 255
    t.string   "api_trigger", limit: 255
    t.string   "status",      limit: 255
    t.index ["created_at"], name: "index_background_tasks_on_created_at", using: :btree
    t.index ["person_id"], name: "index_background_tasks_on_person_id", using: :btree
    t.index ["updated_at"], name: "index_background_tasks_on_updated_at", using: :btree
  end

  create_table "bank_import_histories", force: :cascade do |t|
    t.string   "file_name",      limit: 255
    t.string   "reference_line", limit: 255
    t.datetime "media_date"
    t.index ["media_date"], name: "index_bank_import_histories_on_media_date", using: :btree
  end

  create_table "cached_documents", force: :cascade do |t|
    t.integer  "validity_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_file_name",    limit: 255
    t.string   "document_content_type", limit: 255
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
    t.index ["created_at"], name: "index_cached_documents_on_created_at", using: :btree
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "resource_id"
    t.string   "resource_type", limit: 255
    t.string   "title",         limit: 255, default: ""
    t.text     "description",               default: ""
    t.boolean  "is_closed",                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_comments_on_created_at", using: :btree
    t.index ["is_closed"], name: "index_comments_on_is_closed", using: :btree
    t.index ["person_id"], name: "index_comments_on_person_id", using: :btree
    t.index ["resource_id"], name: "index_comments_on_resource_id", using: :btree
    t.index ["resource_type"], name: "index_comments_on_resource_type", using: :btree
    t.index ["updated_at"], name: "index_comments_on_updated_at", using: :btree
  end

  create_table "creditors", force: :cascade do |t|
    t.integer  "creditor_id"
    t.integer  "affair_id"
    t.string   "title",                limit: 255
    t.text     "description"
    t.integer  "value_in_cents",                   default: 0,     null: false
    t.string   "value_currency",       limit: 255, default: "CHF", null: false
    t.integer  "vat_in_cents",                     default: 0,     null: false
    t.string   "vat_currency",         limit: 255, default: "CHF", null: false
    t.string   "vat_percentage",       limit: 255
    t.date     "invoice_received_on"
    t.date     "invoice_ends_on"
    t.date     "invoice_in_books_on"
    t.float    "discount_percentage",              default: 0.0
    t.date     "discount_ends_on"
    t.date     "paid_on"
    t.date     "payment_in_books_on"
    t.string   "account",              limit: 255
    t.string   "transitional_account", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "discount_account",     limit: 255
    t.string   "vat_account",          limit: 255
    t.string   "vat_discount_account", limit: 255
    t.index ["affair_id"], name: "index_creditors_on_affair_id", using: :btree
    t.index ["creditor_id"], name: "index_creditors_on_creditor_id", using: :btree
    t.index ["discount_ends_on"], name: "index_creditors_on_discount_ends_on", using: :btree
    t.index ["invoice_ends_on"], name: "index_creditors_on_invoice_ends_on", using: :btree
    t.index ["invoice_in_books_on"], name: "index_creditors_on_invoice_in_books_on", using: :btree
    t.index ["invoice_received_on"], name: "index_creditors_on_invoice_received_on", using: :btree
    t.index ["paid_on"], name: "index_creditors_on_paid_on", using: :btree
    t.index ["payment_in_books_on"], name: "index_creditors_on_payment_in_books_on", using: :btree
  end

  create_table "currencies", force: :cascade do |t|
    t.integer "priority"
    t.string  "iso_code",        limit: 255, null: false
    t.string  "iso_numeric",     limit: 255
    t.string  "name",            limit: 255
    t.string  "symbol",          limit: 255
    t.string  "subunit",         limit: 255
    t.integer "subunit_to_unit"
    t.string  "separator",       limit: 255
    t.string  "delimiter",       limit: 255
    t.index ["iso_code"], name: "index_currencies_on_iso_code", using: :btree
    t.index ["priority"], name: "index_currencies_on_priority", using: :btree
  end

  create_table "currency_rates", force: :cascade do |t|
    t.integer  "from_currency_id", null: false
    t.integer  "to_currency_id",   null: false
    t.float    "rate",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["from_currency_id"], name: "index_currency_rates_on_from_currency_id", using: :btree
    t.index ["rate"], name: "index_currency_rates_on_rate", using: :btree
    t.index ["to_currency_id"], name: "index_currency_rates_on_to_currency_id", using: :btree
  end

  create_table "employment_contracts", force: :cascade do |t|
    t.integer  "person_id"
    t.float    "percentage"
    t.date     "interval_starts_on"
    t.date     "interval_ends_on"
    t.text     "description",        default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_employment_contracts_on_created_at", using: :btree
    t.index ["interval_ends_on"], name: "index_employment_contracts_on_interval_ends_on", using: :btree
    t.index ["interval_starts_on"], name: "index_employment_contracts_on_interval_starts_on", using: :btree
    t.index ["person_id"], name: "index_employment_contracts_on_person_id", using: :btree
    t.index ["updated_at"], name: "index_employment_contracts_on_updated_at", using: :btree
  end

  create_table "extras", force: :cascade do |t|
    t.integer  "affair_id"
    t.string   "title",          limit: 255
    t.text     "description"
    t.integer  "value_in_cents"
    t.string   "value_currency", limit: 255
    t.float    "quantity"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vat_in_cents",               default: 0,     null: false
    t.string   "vat_currency",   limit: 255, default: "CHF", null: false
    t.float    "vat_percentage"
    t.index ["affair_id"], name: "index_extras_on_affair_id", using: :btree
    t.index ["position"], name: "index_extras_on_position", using: :btree
    t.index ["quantity"], name: "index_extras_on_quantity", using: :btree
    t.index ["value_in_cents"], name: "index_extras_on_value_in_cents", using: :btree
    t.index ["vat_in_cents"], name: "index_extras_on_vat_in_cents", using: :btree
  end

  create_table "generic_templates", force: :cascade do |t|
    t.string   "title",                 limit: 255,                 null: false
    t.string   "snapshot_file_name",    limit: 255
    t.string   "snapshot_content_type", limit: 255
    t.integer  "snapshot_file_size"
    t.datetime "snapshot_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "language_id",                                       null: false
    t.string   "class_name",            limit: 255
    t.string   "odt_file_name",         limit: 255
    t.string   "odt_content_type",      limit: 255
    t.integer  "odt_file_size"
    t.datetime "odt_updated_at"
    t.boolean  "plural",                            default: false, null: false
    t.index ["language_id"], name: "index_salaries_salary_templates_on_language_id", using: :btree
    t.index ["odt_updated_at"], name: "index_generic_templates_on_odt_updated_at", using: :btree
  end

  create_table "invoice_templates", force: :cascade do |t|
    t.string   "title",                  limit: 255, default: "",    null: false
    t.text     "html",                               default: "",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "with_bvr",                           default: false
    t.text     "bvr_address",                        default: ""
    t.string   "bvr_account",            limit: 255, default: ""
    t.string   "snapshot_file_name",     limit: 255
    t.string   "snapshot_content_type",  limit: 255
    t.integer  "snapshot_file_size"
    t.datetime "snapshot_updated_at"
    t.boolean  "show_invoice_value",                 default: true
    t.integer  "language_id",                                        null: false
    t.string   "account_identification", limit: 255
    t.string   "odt_file_name",          limit: 255
    t.string   "odt_content_type",       limit: 255
    t.integer  "odt_file_size"
    t.datetime "odt_updated_at"
    t.index ["language_id"], name: "index_invoice_templates_on_language_id", using: :btree
  end

  create_table "invoices", force: :cascade do |t|
    t.string   "title",               limit: 255, default: ""
    t.text     "description",                     default: ""
    t.bigint   "value_in_cents",                                  null: false
    t.string   "value_currency",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "affair_id"
    t.text     "printed_address",                 default: ""
    t.integer  "invoice_template_id",                             null: false
    t.string   "pdf_file_name",       limit: 255
    t.string   "pdf_content_type",    limit: 255
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.integer  "status",                          default: 0,     null: false
    t.boolean  "cancelled",                       default: false, null: false
    t.boolean  "offered",                         default: false, null: false
    t.integer  "vat_in_cents",                    default: 0,     null: false
    t.string   "vat_currency",        limit: 255, default: "CHF", null: false
    t.float    "vat_percentage"
    t.text     "conditions"
    t.integer  "condition_id"
    t.index ["affair_id"], name: "index_invoices_on_affair_id", using: :btree
    t.index ["condition_id"], name: "index_invoices_on_condition_id", using: :btree
    t.index ["created_at"], name: "index_invoices_on_created_at", using: :btree
    t.index ["invoice_template_id"], name: "index_invoices_on_invoice_template_id", using: :btree
    t.index ["pdf_updated_at"], name: "index_invoices_on_pdf_updated_at", using: :btree
    t.index ["status"], name: "index_invoices_on_status", using: :btree
    t.index ["updated_at"], name: "index_invoices_on_updated_at", using: :btree
    t.index ["value_currency"], name: "index_invoices_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_invoices_on_value_in_cents", using: :btree
    t.index ["vat_in_cents"], name: "index_invoices_on_vat_in_cents", using: :btree
  end

  create_table "jobs", force: :cascade do |t|
    t.string "name",        limit: 255, default: ""
    t.text   "description",             default: ""
    t.index ["name"], name: "index_jobs_on_name", using: :btree
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", limit: 255, default: ""
    t.string "code", limit: 255, default: ""
    t.index ["code"], name: "index_languages_on_code", using: :btree
    t.index ["name"], name: "index_languages_on_name", using: :btree
  end

  create_table "locations", force: :cascade do |t|
    t.integer "parent_id"
    t.string  "name",               limit: 255, default: ""
    t.string  "iso_code_a2",        limit: 255, default: ""
    t.string  "iso_code_a3",        limit: 255, default: ""
    t.string  "iso_code_num",       limit: 255, default: ""
    t.string  "postal_code_prefix", limit: 255, default: ""
    t.string  "phone_prefix",       limit: 255, default: ""
    t.index ["iso_code_a2"], name: "index_locations_on_iso_code_a2", using: :btree
    t.index ["iso_code_a3"], name: "index_locations_on_iso_code_a3", using: :btree
    t.index ["name"], name: "index_locations_on_name", using: :btree
    t.index ["parent_id"], name: "index_locations_on_parent_id", using: :btree
    t.index ["postal_code_prefix"], name: "index_locations_on_postal_code_prefix", using: :btree
  end

  create_table "logs", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "resource_id"
    t.string   "resource_type", limit: 255
    t.string   "action",        limit: 255
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_logs_on_created_at", using: :btree
    t.index ["person_id"], name: "index_logs_on_person_id", using: :btree
    t.index ["resource_id"], name: "index_logs_on_resource_id", using: :btree
    t.index ["resource_type"], name: "index_logs_on_resource_type", using: :btree
    t.index ["updated_at"], name: "index_logs_on_updated_at", using: :btree
  end

  create_table "people", force: :cascade do |t|
    t.integer  "job_id"
    t.integer  "location_id"
    t.integer  "main_communication_language_id"
    t.boolean  "is_an_organization",                         default: false, null: false
    t.string   "organization_name",              limit: 255, default: ""
    t.string   "title",                          limit: 255, default: ""
    t.string   "first_name",                     limit: 255, default: ""
    t.string   "last_name",                      limit: 255, default: ""
    t.string   "phone",                          limit: 255, default: ""
    t.string   "second_phone",                   limit: 255, default: ""
    t.string   "mobile",                         limit: 255, default: ""
    t.string   "email",                          limit: 255, default: "",    null: false
    t.string   "second_email",                   limit: 255, default: ""
    t.text     "address",                                    default: ""
    t.date     "birth_date"
    t.string   "nationality",                    limit: 255, default: ""
    t.string   "avs_number",                     limit: 255, default: ""
    t.text     "bank_informations",                          default: ""
    t.string   "encrypted_password",             limit: 128, default: "",    null: false
    t.string   "reset_password_token",           limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                              default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",             limit: 255
    t.string   "last_sign_in_ip",                limit: 255
    t.string   "password_salt",                  limit: 255
    t.integer  "failed_attempts",                            default: 0
    t.string   "unlock_token",                   limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",                                     default: false, null: false
    t.boolean  "gender"
    t.integer  "task_rate_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "website",                        limit: 255
    t.string   "alias_name",                     limit: 255, default: ""
    t.string   "fax_number",                     limit: 255, default: ""
    t.string   "creditor_account",               limit: 255
    t.string   "creditor_transitional_account",  limit: 255
    t.string   "creditor_vat_account",           limit: 255
    t.string   "creditor_vat_discount_account",  limit: 255
    t.string   "creditor_discount_account",      limit: 255
    t.index ["authentication_token"], name: "index_people_on_authentication_token", unique: true, using: :btree
    t.index ["created_at"], name: "index_people_on_created_at", using: :btree
    t.index ["email"], name: "index_people_on_email", using: :btree
    t.index ["fax_number"], name: "index_people_on_fax_number", using: :btree
    t.index ["first_name", "last_name"], name: "index_people_on_first_name_and_last_name", using: :btree
    t.index ["first_name"], name: "index_people_on_first_name", using: :btree
    t.index ["gender"], name: "index_people_on_gender", using: :btree
    t.index ["hidden"], name: "index_people_on_hidden", using: :btree
    t.index ["is_an_organization"], name: "index_people_on_is_an_organization", using: :btree
    t.index ["job_id"], name: "index_people_on_job_id", using: :btree
    t.index ["last_name"], name: "index_people_on_last_name", using: :btree
    t.index ["location_id"], name: "index_people_on_location_id", using: :btree
    t.index ["main_communication_language_id"], name: "index_people_on_main_communication_language_id", using: :btree
    t.index ["organization_name"], name: "index_people_on_organization_name", using: :btree
    t.index ["reset_password_token"], name: "index_people_on_reset_password_token", unique: true, using: :btree
    t.index ["second_email"], name: "index_people_on_second_email", using: :btree
    t.index ["task_rate_id"], name: "index_people_on_task_rate_id", using: :btree
    t.index ["unlock_token"], name: "index_people_on_unlock_token", unique: true, using: :btree
    t.index ["updated_at"], name: "index_people_on_updated_at", using: :btree
  end

  create_table "people_communication_languages", id: false, force: :cascade do |t|
    t.integer "person_id"
    t.integer "language_id"
    t.index ["language_id"], name: "people_language_id_index", using: :btree
    t.index ["person_id", "language_id"], name: "people_communication_languages_index", using: :btree
    t.index ["person_id"], name: "people_person_id_index", using: :btree
  end

  create_table "people_private_tags", id: false, force: :cascade do |t|
    t.integer "person_id"
    t.integer "private_tag_id"
    t.index ["person_id"], name: "index_people_private_tags_on_person_id", using: :btree
    t.index ["private_tag_id"], name: "index_people_private_tags_on_private_tag_id", using: :btree
  end

  create_table "people_public_tags", id: false, force: :cascade do |t|
    t.integer "person_id"
    t.integer "public_tag_id"
    t.index ["person_id"], name: "index_people_public_tags_on_person_id", using: :btree
    t.index ["public_tag_id"], name: "index_people_public_tags_on_public_tag_id", using: :btree
  end

  create_table "people_roles", id: false, force: :cascade do |t|
    t.integer "person_id"
    t.integer "role_id"
    t.index ["person_id", "role_id"], name: "index_people_roles_on_person_id_and_role_id", using: :btree
    t.index ["person_id"], name: "index_people_roles_on_person_id", using: :btree
    t.index ["role_id"], name: "index_people_roles_on_role_id", using: :btree
  end

  create_table "permissions", force: :cascade do |t|
    t.integer  "role_id"
    t.string   "action",          limit: 255, default: ""
    t.string   "subject",         limit: 255, default: ""
    t.text     "hash_conditions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["action"], name: "index_permissions_on_action", using: :btree
    t.index ["role_id"], name: "index_permissions_on_role_id", using: :btree
    t.index ["subject"], name: "index_permissions_on_subject", using: :btree
  end

  create_table "private_tags", force: :cascade do |t|
    t.integer "parent_id"
    t.string  "name",      limit: 255, default: "", null: false
    t.string  "color",     limit: 255
    t.index ["name"], name: "index_private_tags_on_name", using: :btree
    t.index ["parent_id"], name: "index_private_tags_on_parent_id", using: :btree
  end

  create_table "product_items", force: :cascade do |t|
    t.integer  "parent_id"
    t.integer  "affair_id"
    t.integer  "product_id"
    t.integer  "program_id"
    t.float    "position"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "bid_percentage"
    t.integer  "value_in_cents",             default: 0,     null: false
    t.string   "value_currency", limit: 255, default: "CHF", null: false
    t.integer  "category_id"
    t.text     "comment"
    t.datetime "ordered_at"
    t.datetime "confirmed_at"
    t.datetime "delivery_at"
    t.date     "warranty_begin"
    t.date     "warranty_end"
    t.index ["affair_id", "product_id", "position"], name: "affairs_products_programs_unique_position", using: :btree
    t.index ["affair_id"], name: "index_product_items_on_affair_id", using: :btree
    t.index ["category_id"], name: "index_product_items_on_category_id", using: :btree
    t.index ["confirmed_at"], name: "index_product_items_on_confirmed_at", using: :btree
    t.index ["delivery_at"], name: "index_product_items_on_delivery_at", using: :btree
    t.index ["ordered_at"], name: "index_product_items_on_ordered_at", using: :btree
    t.index ["parent_id"], name: "index_product_items_on_parent_id", using: :btree
    t.index ["product_id"], name: "index_product_items_on_product_id", using: :btree
    t.index ["program_id"], name: "index_product_items_on_program_id", using: :btree
  end

  create_table "product_programs", force: :cascade do |t|
    t.string   "key",           limit: 255,                 null: false
    t.string   "program_group", limit: 255,                 null: false
    t.string   "title",         limit: 255
    t.text     "description"
    t.boolean  "archive",                   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["archive"], name: "index_product_programs_on_archive", using: :btree
    t.index ["key"], name: "index_product_programs_on_key", using: :btree
    t.index ["program_group"], name: "index_product_programs_on_program_group", using: :btree
    t.index ["title"], name: "index_product_programs_on_title", using: :btree
  end

  create_table "product_variants", force: :cascade do |t|
    t.integer  "product_id",                                         null: false
    t.string   "program_group",          limit: 255,                 null: false
    t.string   "title",                  limit: 255
    t.integer  "buying_price_in_cents"
    t.string   "buying_price_currency",  limit: 255, default: "CHF", null: false
    t.integer  "selling_price_in_cents",                             null: false
    t.string   "selling_price_currency", limit: 255, default: "CHF"
    t.integer  "art_in_cents"
    t.string   "art_currency",           limit: 255, default: "CHF"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vat_in_cents",                       default: 0,     null: false
    t.string   "vat_currency",           limit: 255, default: "CHF", null: false
    t.integer  "vat_percentage"
    t.index ["art_in_cents"], name: "index_product_variants_on_art_in_cents", using: :btree
    t.index ["buying_price_in_cents"], name: "index_product_variants_on_buying_price_in_cents", using: :btree
    t.index ["product_id"], name: "index_product_variants_on_product_id", using: :btree
    t.index ["program_group"], name: "index_product_variants_on_program_group", using: :btree
    t.index ["selling_price_in_cents"], name: "index_product_variants_on_selling_price_in_cents", using: :btree
    t.index ["vat_in_cents"], name: "index_product_variants_on_vat_in_cents", using: :btree
  end

  create_table "products", force: :cascade do |t|
    t.integer  "provider_id"
    t.integer  "after_sale_id"
    t.string   "key",                limit: 255,                 null: false
    t.string   "title",              limit: 255
    t.string   "category",           limit: 255
    t.text     "description"
    t.boolean  "has_accessories",                default: false, null: false
    t.boolean  "archive",                        default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unit_symbol",        limit: 255
    t.integer  "price_to_unit_rate"
    t.integer  "width"
    t.integer  "height"
    t.integer  "depth"
    t.integer  "volume"
    t.integer  "weight"
    t.index ["after_sale_id"], name: "index_products_on_after_sale_id", using: :btree
    t.index ["category"], name: "index_products_on_category", using: :btree
    t.index ["has_accessories"], name: "index_products_on_has_accessories", using: :btree
    t.index ["key"], name: "index_products_on_key", using: :btree
    t.index ["provider_id"], name: "index_products_on_provider_id", using: :btree
    t.index ["title"], name: "index_products_on_title", using: :btree
  end

  create_table "public_tags", force: :cascade do |t|
    t.integer "parent_id"
    t.string  "name",      limit: 255, default: "", null: false
    t.string  "color",     limit: 255
    t.index ["name"], name: "index_public_tags_on_name", using: :btree
    t.index ["parent_id"], name: "index_public_tags_on_parent_id", using: :btree
  end

  create_table "query_presets", force: :cascade do |t|
    t.string "name",  limit: 255, default: ""
    t.text   "query",             default: ""
    t.index ["name"], name: "index_query_presets_on_name", using: :btree
    t.index ["query"], name: "index_query_presets_on_query", using: :btree
  end

  create_table "receipts", force: :cascade do |t|
    t.integer  "invoice_id"
    t.bigint   "value_in_cents"
    t.string   "value_currency",   limit: 255
    t.date     "value_date"
    t.string   "means_of_payment", limit: 255, default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_receipts_on_created_at", using: :btree
    t.index ["invoice_id"], name: "index_receipts_on_invoice_id", using: :btree
    t.index ["means_of_payment"], name: "index_receipts_on_means_of_payment", using: :btree
    t.index ["updated_at"], name: "index_receipts_on_updated_at", using: :btree
    t.index ["value_currency"], name: "index_receipts_on_value_currency", using: :btree
    t.index ["value_date"], name: "index_receipts_on_value_date", using: :btree
    t.index ["value_in_cents"], name: "index_receipts_on_value_in_cents", using: :btree
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",        limit: 255, default: ""
    t.text     "description",             default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_roles_on_name", using: :btree
  end

  create_table "salaries", force: :cascade do |t|
    t.integer  "parent_id"
    t.integer  "person_id",                                                               null: false
    t.date     "from"
    t.date     "to"
    t.string   "title",                                       limit: 255,                 null: false
    t.boolean  "is_reference",                                            default: false, null: false
    t.boolean  "married",                                                 default: false, null: false
    t.integer  "children_count",                                          default: 0,     null: false
    t.bigint   "yearly_salary_in_cents"
    t.integer  "yearly_salary_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "generic_template_id",                                                     null: false
    t.string   "pdf_file_name",                               limit: 255
    t.string   "pdf_content_type",                            limit: 255
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.integer  "activity_rate"
    t.boolean  "paid",                                                    default: false
    t.string   "brut_account",                                limit: 255
    t.string   "net_account",                                 limit: 255
    t.bigint   "cert_transport_in_cents",                                 default: 0,     null: false
    t.string   "cert_transport_currency",                     limit: 255, default: "CHF", null: false
    t.bigint   "cert_food_in_cents",                                      default: 0,     null: false
    t.string   "cert_food_currency",                          limit: 255, default: "CHF", null: false
    t.bigint   "cert_logding_in_cents",                                   default: 0,     null: false
    t.string   "cert_logding_currency",                       limit: 255, default: "CHF", null: false
    t.bigint   "cert_misc_salary_car_in_cents",                           default: 0,     null: false
    t.string   "cert_misc_salary_car_currency",               limit: 255, default: "CHF", null: false
    t.string   "cert_misc_salary_other_title",                limit: 255, default: "",    null: false
    t.bigint   "cert_misc_salary_other_value_in_cents",                   default: 0,     null: false
    t.string   "cert_misc_salary_other_value_currency",       limit: 255, default: "CHF", null: false
    t.string   "cert_non_periodic_title",                     limit: 255, default: "",    null: false
    t.bigint   "cert_non_periodic_value_in_cents",                        default: 0,     null: false
    t.string   "cert_non_periodic_value_currency",            limit: 255, default: "CHF", null: false
    t.string   "cert_capital_title",                          limit: 255, default: "",    null: false
    t.bigint   "cert_capital_value_in_cents",                             default: 0,     null: false
    t.string   "cert_capital_value_currency",                 limit: 255, default: "CHF", null: false
    t.bigint   "cert_participation_in_cents",                             default: 0,     null: false
    t.string   "cert_participation_currency",                 limit: 255, default: "CHF", null: false
    t.bigint   "cert_compentation_admin_members_in_cents",                default: 0,     null: false
    t.string   "cert_compentation_admin_members_currency",    limit: 255, default: "CHF", null: false
    t.string   "cert_misc_other_title",                       limit: 255, default: "",    null: false
    t.bigint   "cert_misc_other_value_in_cents",                          default: 0,     null: false
    t.string   "cert_misc_other_value_currency",              limit: 255, default: "CHF", null: false
    t.bigint   "cert_avs_ac_aanp_in_cents",                               default: 0,     null: false
    t.string   "cert_avs_ac_aanp_currency",                   limit: 255, default: "CHF", null: false
    t.bigint   "cert_lpp_in_cents",                                       default: 0,     null: false
    t.string   "cert_lpp_currency",                           limit: 255, default: "CHF", null: false
    t.bigint   "cert_buy_lpp_in_cents",                                   default: 0,     null: false
    t.string   "cert_buy_lpp_currency",                       limit: 255, default: "CHF", null: false
    t.bigint   "cert_is_in_cents",                                        default: 0,     null: false
    t.string   "cert_is_currency",                            limit: 255, default: "CHF", null: false
    t.bigint   "cert_alloc_traveling_in_cents",                           default: 0,     null: false
    t.string   "cert_alloc_traveling_currency",               limit: 255, default: "CHF", null: false
    t.bigint   "cert_alloc_food_in_cents",                                default: 0,     null: false
    t.string   "cert_alloc_food_currency",                    limit: 255, default: "CHF", null: false
    t.string   "cert_alloc_other_actual_cost_title",          limit: 255, default: "",    null: false
    t.bigint   "cert_alloc_other_actual_cost_value_in_cents",             default: 0,     null: false
    t.string   "cert_alloc_other_actual_cost_value_currency", limit: 255, default: "CHF", null: false
    t.bigint   "cert_alloc_representation_in_cents",                      default: 0,     null: false
    t.string   "cert_alloc_representation_currency",          limit: 255, default: "CHF", null: false
    t.bigint   "cert_alloc_car_in_cents",                                 default: 0,     null: false
    t.string   "cert_alloc_car_currency",                     limit: 255, default: "CHF", null: false
    t.string   "cert_alloc_other_fixed_fees_title",           limit: 255, default: "",    null: false
    t.bigint   "cert_alloc_other_fixed_fees_value_in_cents",              default: 0,     null: false
    t.string   "cert_alloc_other_fixed_fees_value_currency",  limit: 255, default: "CHF", null: false
    t.bigint   "cert_formation_in_cents",                                 default: 0,     null: false
    t.string   "cert_formation_currency",                     limit: 255, default: "CHF", null: false
    t.string   "cert_others_title",                           limit: 255, default: "",    null: false
    t.text     "cert_notes",                                              default: "",    null: false
    t.string   "employer_account",                            limit: 255, default: ""
    t.text     "comments"
    t.string   "yearly_salary_currency",                      limit: 255, default: "CHF", null: false
    t.index ["is_reference"], name: "index_salaries_on_is_template", using: :btree
    t.index ["paid"], name: "index_salaries_on_paid", using: :btree
    t.index ["parent_id"], name: "index_salaries_on_parent_id", using: :btree
    t.index ["person_id"], name: "index_salaries_on_person_id", using: :btree
  end

  create_table "salaries_items", force: :cascade do |t|
    t.integer  "parent_id"
    t.integer  "salary_id",                                  null: false
    t.integer  "position",                                   null: false
    t.string   "title",          limit: 255,                 null: false
    t.bigint   "value_in_cents",                             null: false
    t.string   "category",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_currency", limit: 255, default: "CHF", null: false
    t.index ["salary_id"], name: "index_salaries_items_on_salary_id", using: :btree
  end

  create_table "salaries_items_taxes", id: false, force: :cascade do |t|
    t.integer "item_id", null: false
    t.integer "tax_id",  null: false
    t.index ["item_id"], name: "index_salaries_items_taxes_on_item_id", using: :btree
    t.index ["tax_id"], name: "index_salaries_items_taxes_on_tax_id", using: :btree
  end

  create_table "salaries_tax_data", force: :cascade do |t|
    t.integer  "salary_id",                                                                   null: false
    t.integer  "tax_id",                                                                      null: false
    t.integer  "position",                                                                    null: false
    t.bigint   "employer_value_in_cents",                                                     null: false
    t.decimal  "employer_percent",                    precision: 6, scale: 3,                 null: false
    t.boolean  "employer_use_percent",                                                        null: false
    t.bigint   "employee_value_in_cents",                                                     null: false
    t.decimal  "employee_percent",                    precision: 6, scale: 3,                 null: false
    t.boolean  "employee_use_percent",                                                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "employee_value_currency", limit: 255,                         default: "CHF", null: false
    t.string   "employer_value_currency", limit: 255,                         default: "CHF", null: false
    t.index ["salary_id"], name: "index_salaries_tax_data_on_salary_id", using: :btree
    t.index ["tax_id"], name: "index_salaries_tax_data_on_tax_id", using: :btree
  end

  create_table "salaries_taxes", force: :cascade do |t|
    t.string   "title",              limit: 255,                 null: false
    t.string   "model",              limit: 255,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "employee_account",   limit: 255
    t.boolean  "exporter_avs_group",             default: false, null: false
    t.boolean  "exporter_lpp_group",             default: false, null: false
    t.boolean  "exporter_is_group",              default: false, null: false
    t.string   "employer_account",   limit: 255, default: ""
    t.boolean  "archive",                        default: false, null: false
    t.index ["archive"], name: "index_salaries_taxes_on_archive", using: :btree
    t.index ["exporter_avs_group"], name: "index_salaries_taxes_on_exporter_avs_group", using: :btree
    t.index ["exporter_is_group"], name: "index_salaries_taxes_on_exporter_is_group", using: :btree
    t.index ["exporter_lpp_group"], name: "index_salaries_taxes_on_exporter_lpp_group", using: :btree
  end

  create_table "salaries_taxes_age", force: :cascade do |t|
    t.integer  "tax_id",                                   null: false
    t.integer  "year",                                     null: false
    t.integer  "men_from",                                 null: false
    t.integer  "men_to",                                   null: false
    t.integer  "women_from",                               null: false
    t.integer  "women_to",                                 null: false
    t.decimal  "employer_percent", precision: 6, scale: 3, null: false
    t.decimal  "employee_percent", precision: 6, scale: 3, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["tax_id"], name: "index_salaries_taxes_age_on_tax_id", using: :btree
    t.index ["year"], name: "index_salaries_taxes_age_on_year", using: :btree
  end

  create_table "salaries_taxes_generic", force: :cascade do |t|
    t.integer  "tax_id",                                                                      null: false
    t.integer  "year",                                                                        null: false
    t.bigint   "salary_from_in_cents"
    t.bigint   "salary_to_in_cents"
    t.bigint   "employer_value_in_cents",                                                     null: false
    t.decimal  "employer_percent",                    precision: 6, scale: 3,                 null: false
    t.boolean  "employer_use_percent",                                                        null: false
    t.bigint   "employee_value_in_cents",                                                     null: false
    t.decimal  "employee_percent",                    precision: 6, scale: 3,                 null: false
    t.boolean  "employee_use_percent",                                                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salary_from_currency",    limit: 255,                         default: "CHF", null: false
    t.string   "salary_to_currency",      limit: 255,                         default: "CHF", null: false
    t.string   "employer_value_currency", limit: 255,                         default: "CHF", null: false
    t.string   "employee_value_currency", limit: 255,                         default: "CHF", null: false
    t.index ["tax_id"], name: "index_salaries_taxes_generic_on_tax_id", using: :btree
    t.index ["year"], name: "index_salaries_taxes_generic_on_year", using: :btree
  end

  create_table "salaries_taxes_is", force: :cascade do |t|
    t.integer  "tax_id",                                                                    null: false
    t.integer  "year",                                                                      null: false
    t.bigint   "yearly_from_in_cents",                                                      null: false
    t.bigint   "yearly_to_in_cents",                                                        null: false
    t.bigint   "monthly_from_in_cents",                                                     null: false
    t.bigint   "monthly_to_in_cents",                                                       null: false
    t.bigint   "hourly_from_in_cents",                                                      null: false
    t.bigint   "hourly_to_in_cents",                                                        null: false
    t.decimal  "percent_alone",                     precision: 7, scale: 2
    t.decimal  "percent_married",                   precision: 7, scale: 2
    t.decimal  "percent_children_1",                precision: 7, scale: 2
    t.decimal  "percent_children_2",                precision: 7, scale: 2
    t.decimal  "percent_children_3",                precision: 7, scale: 2
    t.decimal  "percent_children_4",                precision: 7, scale: 2
    t.decimal  "percent_children_5",                precision: 7, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "yearly_from_currency",  limit: 255,                         default: "CHF", null: false
    t.string   "yearly_to_currency",    limit: 255,                         default: "CHF", null: false
    t.string   "monthly_from_currency", limit: 255,                         default: "CHF", null: false
    t.string   "monthly_to_currency",   limit: 255,                         default: "CHF", null: false
    t.string   "hourly_from_currency",  limit: 255,                         default: "CHF", null: false
    t.string   "hourly_to_currency",    limit: 255,                         default: "CHF", null: false
    t.index ["tax_id"], name: "index_salaries_taxes_is_on_tax_id", using: :btree
    t.index ["year"], name: "index_salaries_taxes_is_on_year", using: :btree
  end

  create_table "salaries_taxes_is2014", force: :cascade do |t|
    t.integer  "tax_id",                                           null: false
    t.integer  "year",                                             null: false
    t.string   "tax_group",            limit: 255,                 null: false
    t.integer  "children_count",                                   null: false
    t.string   "ecclesiastical",       limit: 255, default: "N",   null: false
    t.integer  "salary_from_in_cents",             default: 0,     null: false
    t.string   "salary_from_currency", limit: 255, default: "CHF", null: false
    t.integer  "salary_to_in_cents",               default: 0,     null: false
    t.string   "salary_to_currency",   limit: 255, default: "CHF", null: false
    t.integer  "tax_value_in_cents",               default: 0,     null: false
    t.string   "tax_value_currency",   limit: 255, default: "CHF", null: false
    t.float    "tax_value_percentage",             default: 0.0,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["tax_id"], name: "index_salaries_taxes_is2014_on_tax_id", using: :btree
    t.index ["year"], name: "index_salaries_taxes_is2014_on_year", using: :btree
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", using: :btree
    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
  end

  create_table "subscription_values", force: :cascade do |t|
    t.integer "subscription_id",                                 null: false
    t.integer "invoice_template_id",                             null: false
    t.integer "private_tag_id"
    t.integer "value_in_cents",                  default: 0
    t.string  "value_currency",      limit: 255, default: "CHF"
    t.integer "position",                                        null: false
    t.index ["position"], name: "index_subscription_values_on_position", using: :btree
    t.index ["private_tag_id"], name: "index_subscription_values_on_private_tag_id", using: :btree
    t.index ["subscription_id"], name: "index_subscription_values_on_subscription_id", using: :btree
    t.index ["value_currency"], name: "index_subscription_values_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_subscription_values_on_value_in_cents", using: :btree
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "title",                     limit: 255, default: "", null: false
    t.text     "description",                           default: ""
    t.date     "interval_starts_on"
    t.date     "interval_ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pdf_file_name",             limit: 255
    t.string   "pdf_content_type",          limit: 255
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.text     "last_pdf_generation_query"
    t.integer  "parent_id"
    t.index ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
    t.index ["interval_ends_on"], name: "index_subscriptions_on_interval_ends_on", using: :btree
    t.index ["interval_starts_on"], name: "index_subscriptions_on_interval_starts_on", using: :btree
    t.index ["parent_id"], name: "index_subscriptions_on_parent_id", using: :btree
    t.index ["pdf_updated_at"], name: "index_subscriptions_on_pdf_updated_at", using: :btree
    t.index ["updated_at"], name: "index_subscriptions_on_updated_at", using: :btree
  end

  create_table "task_presets", force: :cascade do |t|
    t.integer "task_type_id"
    t.string  "title",          limit: 255, default: "", null: false
    t.text    "description",                default: ""
    t.float   "duration"
    t.integer "value_in_cents"
    t.string  "value_currency", limit: 255
    t.index ["task_type_id"], name: "index_task_presets_on_task_type_id", using: :btree
    t.index ["title"], name: "index_task_presets_on_title", using: :btree
    t.index ["value_currency"], name: "index_task_presets_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_task_presets_on_value_in_cents", using: :btree
  end

  create_table "task_rates", force: :cascade do |t|
    t.string   "title",          limit: 255,                 null: false
    t.text     "description"
    t.integer  "value_in_cents",                             null: false
    t.string   "value_currency", limit: 255, default: "CHF"
    t.boolean  "archive",                    default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["archive"], name: "index_task_rates_on_archive", using: :btree
    t.index ["value_currency"], name: "index_task_rates_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_task_rates_on_value_in_cents", using: :btree
  end

  create_table "task_types", force: :cascade do |t|
    t.string  "title",          limit: 255, default: "",    null: false
    t.text    "description",                default: ""
    t.float   "ratio",                                      null: false
    t.integer "value_in_cents"
    t.string  "value_currency", limit: 255, default: "CHF"
    t.boolean "archive",                    default: false
    t.index ["archive"], name: "index_task_types_on_archive", using: :btree
    t.index ["title"], name: "index_task_types_on_title", using: :btree
    t.index ["value_currency"], name: "index_task_types_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_task_types_on_value_in_cents", using: :btree
  end

  create_table "tasks", force: :cascade do |t|
    t.integer  "executer_id",                                null: false
    t.text     "description",                default: ""
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "affair_id",                                  null: false
    t.integer  "task_type_id",                               null: false
    t.bigint   "value_in_cents",             default: 0,     null: false
    t.string   "value_currency", limit: 255, default: "CHF", null: false
    t.integer  "salary_id"
    t.datetime "start_date"
    t.integer  "creator_id"
    t.index ["affair_id"], name: "index_tasks_on_affair_id", using: :btree
    t.index ["creator_id"], name: "index_tasks_on_creator_id", using: :btree
    t.index ["duration"], name: "index_tasks_on_duration", using: :btree
    t.index ["executer_id"], name: "index_tasks_on_executer_id", using: :btree
    t.index ["salary_id"], name: "index_tasks_on_salary_id", using: :btree
    t.index ["start_date"], name: "index_tasks_on_start_date", using: :btree
    t.index ["task_type_id"], name: "index_tasks_on_task_type_id", using: :btree
    t.index ["value_currency"], name: "index_tasks_on_value_currency", using: :btree
    t.index ["value_in_cents"], name: "index_tasks_on_value_in_cents", using: :btree
  end

end
