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

ActiveRecord::Schema.define(version: 20160606154722) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "affairs", force: true do |t|
    t.integer  "owner_id",                                  null: false
    t.integer  "buyer_id",                                  null: false
    t.integer  "receiver_id",                               null: false
    t.string   "title",                     default: "",    null: false
    t.text     "description",               default: ""
    t.integer  "value_in_cents",  limit: 8, default: 0,     null: false
    t.string   "value_currency",            default: "CHF", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                    default: 0,     null: false
    t.boolean  "estimate",                  default: false, null: false
    t.integer  "parent_id"
    t.text     "footer"
    t.text     "conditions"
    t.integer  "seller_id",                 default: 1,     null: false
    t.integer  "condition_id"
    t.boolean  "unbillable",                default: false, null: false
    t.text     "notes"
    t.float    "vat_percentage"
    t.integer  "vat_in_cents",              default: 0,     null: false
    t.string   "vat_currency",              default: "CHF", null: false
    t.string   "alias_name"
    t.text     "execution_notes"
    t.boolean  "archive",                   default: false, null: false
    t.datetime "sold_at"
  end

  add_index "affairs", ["alias_name"], name: "index_affairs_on_alias_name", using: :btree
  add_index "affairs", ["archive"], name: "index_affairs_on_archive", using: :btree
  add_index "affairs", ["buyer_id"], name: "index_affairs_on_buyer_id", using: :btree
  add_index "affairs", ["condition_id"], name: "index_affairs_on_condition_id", using: :btree
  add_index "affairs", ["created_at"], name: "index_affairs_on_created_at", using: :btree
  add_index "affairs", ["estimate"], name: "index_affairs_on_estimate", using: :btree
  add_index "affairs", ["owner_id"], name: "index_affairs_on_owner_id", using: :btree
  add_index "affairs", ["parent_id"], name: "index_affairs_on_parent_id", using: :btree
  add_index "affairs", ["receiver_id"], name: "index_affairs_on_receiver_id", using: :btree
  add_index "affairs", ["seller_id"], name: "index_affairs_on_seller_id", using: :btree
  add_index "affairs", ["sold_at"], name: "index_affairs_on_sold_at", using: :btree
  add_index "affairs", ["status"], name: "index_affairs_on_status", using: :btree
  add_index "affairs", ["updated_at"], name: "index_affairs_on_updated_at", using: :btree
  add_index "affairs", ["value_currency"], name: "index_affairs_on_value_currency", using: :btree
  add_index "affairs", ["value_in_cents"], name: "index_affairs_on_value_in_cents", using: :btree
  add_index "affairs", ["vat_currency"], name: "index_affairs_on_vat_currency", using: :btree
  add_index "affairs", ["vat_in_cents"], name: "index_affairs_on_vat_in_cents", using: :btree
  add_index "affairs", ["vat_percentage"], name: "index_affairs_on_vat_percentage", using: :btree

  create_table "affairs_conditions", force: true do |t|
    t.string  "title"
    t.text    "description"
    t.boolean "archive",     default: false, null: false
  end

  create_table "affairs_products_categories", force: true do |t|
    t.integer "affair_id", null: false
    t.string  "title"
    t.integer "position",  null: false
  end

  add_index "affairs_products_categories", ["affair_id"], name: "index_affairs_products_categories_on_affair_id", using: :btree
  add_index "affairs_products_categories", ["position"], name: "index_affairs_products_categories_on_position", using: :btree

  create_table "affairs_stakeholders", force: true do |t|
    t.integer "person_id"
    t.integer "affair_id"
    t.string  "title"
  end

  add_index "affairs_stakeholders", ["affair_id"], name: "index_affairs_stakeholders_on_affair_id", using: :btree
  add_index "affairs_stakeholders", ["person_id"], name: "index_affairs_stakeholders_on_person_id", using: :btree

  create_table "affairs_subscriptions", id: false, force: true do |t|
    t.integer "affair_id"
    t.integer "subscription_id"
  end

  add_index "affairs_subscriptions", ["affair_id"], name: "index_affairs_subscriptions_on_affair_id", using: :btree
  add_index "affairs_subscriptions", ["subscription_id"], name: "index_affairs_subscriptions_on_subscription_id", using: :btree

  create_table "application_settings", force: true do |t|
    t.string "key",                 default: ""
    t.text   "value",               default: ""
    t.string "type_for_validation", default: "string", null: false
  end

  add_index "application_settings", ["key"], name: "index_application_settings_on_key", using: :btree

  create_table "background_tasks", force: true do |t|
    t.string   "type"
    t.text     "options"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.integer  "person_id"
    t.string   "ui_trigger"
    t.string   "api_trigger"
    t.string   "status"
  end

  add_index "background_tasks", ["created_at"], name: "index_background_tasks_on_created_at", using: :btree
  add_index "background_tasks", ["person_id"], name: "index_background_tasks_on_person_id", using: :btree
  add_index "background_tasks", ["updated_at"], name: "index_background_tasks_on_updated_at", using: :btree

  create_table "bank_import_histories", force: true do |t|
    t.string   "file_name"
    t.string   "reference_line"
    t.datetime "media_date"
  end

  add_index "bank_import_histories", ["media_date"], name: "index_bank_import_histories_on_media_date", using: :btree

  create_table "cached_documents", force: true do |t|
    t.integer  "validity_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
  end

  add_index "cached_documents", ["created_at"], name: "index_cached_documents_on_created_at", using: :btree

  create_table "comments", force: true do |t|
    t.integer  "person_id"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.string   "title",         default: ""
    t.text     "description",   default: ""
    t.boolean  "is_closed",     default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["created_at"], name: "index_comments_on_created_at", using: :btree
  add_index "comments", ["is_closed"], name: "index_comments_on_is_closed", using: :btree
  add_index "comments", ["person_id"], name: "index_comments_on_person_id", using: :btree
  add_index "comments", ["resource_id"], name: "index_comments_on_resource_id", using: :btree
  add_index "comments", ["resource_type"], name: "index_comments_on_resource_type", using: :btree
  add_index "comments", ["updated_at"], name: "index_comments_on_updated_at", using: :btree

  create_table "creditors", force: true do |t|
    t.integer  "creditor_id"
    t.integer  "affair_id"
    t.string   "title"
    t.text     "description"
    t.integer  "value_in_cents",       default: 0,     null: false
    t.string   "value_currency",       default: "CHF", null: false
    t.integer  "vat_in_cents",         default: 0,     null: false
    t.string   "vat_currency",         default: "CHF", null: false
    t.string   "vat_percentage"
    t.date     "invoice_received_on"
    t.date     "invoice_ends_on"
    t.date     "invoice_in_books_on"
    t.float    "discount_percentage",  default: 0.0
    t.date     "discount_ends_on"
    t.date     "paid_on"
    t.date     "payment_in_books_on"
    t.string   "account"
    t.string   "transitional_account"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "discount_account"
    t.string   "vat_account"
    t.string   "vat_discount_account"
  end

  add_index "creditors", ["affair_id"], name: "index_creditors_on_affair_id", using: :btree
  add_index "creditors", ["creditor_id"], name: "index_creditors_on_creditor_id", using: :btree
  add_index "creditors", ["discount_ends_on"], name: "index_creditors_on_discount_ends_on", using: :btree
  add_index "creditors", ["invoice_ends_on"], name: "index_creditors_on_invoice_ends_on", using: :btree
  add_index "creditors", ["invoice_in_books_on"], name: "index_creditors_on_invoice_in_books_on", using: :btree
  add_index "creditors", ["invoice_received_on"], name: "index_creditors_on_invoice_received_on", using: :btree
  add_index "creditors", ["paid_on"], name: "index_creditors_on_paid_on", using: :btree
  add_index "creditors", ["payment_in_books_on"], name: "index_creditors_on_payment_in_books_on", using: :btree

  create_table "currencies", force: true do |t|
    t.integer "priority"
    t.string  "iso_code",        null: false
    t.string  "iso_numeric"
    t.string  "name"
    t.string  "symbol"
    t.string  "subunit"
    t.integer "subunit_to_unit"
    t.string  "separator"
    t.string  "delimiter"
  end

  add_index "currencies", ["iso_code"], name: "index_currencies_on_iso_code", using: :btree
  add_index "currencies", ["priority"], name: "index_currencies_on_priority", using: :btree

  create_table "currency_rates", force: true do |t|
    t.integer  "from_currency_id", null: false
    t.integer  "to_currency_id",   null: false
    t.float    "rate",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "currency_rates", ["from_currency_id"], name: "index_currency_rates_on_from_currency_id", using: :btree
  add_index "currency_rates", ["rate"], name: "index_currency_rates_on_rate", using: :btree
  add_index "currency_rates", ["to_currency_id"], name: "index_currency_rates_on_to_currency_id", using: :btree

  create_table "employment_contracts", force: true do |t|
    t.integer  "person_id"
    t.float    "percentage"
    t.date     "interval_starts_on"
    t.date     "interval_ends_on"
    t.text     "description",        default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "employment_contracts", ["created_at"], name: "index_employment_contracts_on_created_at", using: :btree
  add_index "employment_contracts", ["interval_ends_on"], name: "index_employment_contracts_on_interval_ends_on", using: :btree
  add_index "employment_contracts", ["interval_starts_on"], name: "index_employment_contracts_on_interval_starts_on", using: :btree
  add_index "employment_contracts", ["person_id"], name: "index_employment_contracts_on_person_id", using: :btree
  add_index "employment_contracts", ["updated_at"], name: "index_employment_contracts_on_updated_at", using: :btree

  create_table "extras", force: true do |t|
    t.integer  "affair_id"
    t.string   "title"
    t.text     "description"
    t.integer  "value_in_cents"
    t.string   "value_currency"
    t.float    "quantity"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vat_in_cents",   default: 0,     null: false
    t.string   "vat_currency",   default: "CHF", null: false
    t.float    "vat_percentage"
  end

  add_index "extras", ["affair_id"], name: "index_extras_on_affair_id", using: :btree
  add_index "extras", ["position"], name: "index_extras_on_position", using: :btree
  add_index "extras", ["quantity"], name: "index_extras_on_quantity", using: :btree
  add_index "extras", ["value_in_cents"], name: "index_extras_on_value_in_cents", using: :btree
  add_index "extras", ["vat_in_cents"], name: "index_extras_on_vat_in_cents", using: :btree

  create_table "generic_templates", force: true do |t|
    t.string   "title",                                 null: false
    t.string   "snapshot_file_name"
    t.string   "snapshot_content_type"
    t.integer  "snapshot_file_size"
    t.datetime "snapshot_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "language_id",                           null: false
    t.string   "class_name"
    t.string   "odt_file_name"
    t.string   "odt_content_type"
    t.integer  "odt_file_size"
    t.datetime "odt_updated_at"
    t.boolean  "plural",                default: false, null: false
  end

  add_index "generic_templates", ["language_id"], name: "index_salaries_salary_templates_on_language_id", using: :btree
  add_index "generic_templates", ["odt_updated_at"], name: "index_generic_templates_on_odt_updated_at", using: :btree

  create_table "invoice_templates", force: true do |t|
    t.string   "title",                  default: "",    null: false
    t.text     "html",                   default: "",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "with_bvr",               default: false
    t.text     "bvr_address",            default: ""
    t.string   "bvr_account",            default: ""
    t.string   "snapshot_file_name"
    t.string   "snapshot_content_type"
    t.integer  "snapshot_file_size"
    t.datetime "snapshot_updated_at"
    t.boolean  "show_invoice_value",     default: true
    t.integer  "language_id",                            null: false
    t.string   "account_identification"
    t.string   "odt_file_name"
    t.string   "odt_content_type"
    t.integer  "odt_file_size"
    t.datetime "odt_updated_at"
  end

  add_index "invoice_templates", ["language_id"], name: "index_invoice_templates_on_language_id", using: :btree

  create_table "invoices", force: true do |t|
    t.string   "title",                         default: ""
    t.text     "description",                   default: ""
    t.integer  "value_in_cents",      limit: 8,                 null: false
    t.string   "value_currency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "affair_id"
    t.text     "printed_address",               default: ""
    t.integer  "invoice_template_id",                           null: false
    t.string   "pdf_file_name"
    t.string   "pdf_content_type"
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.integer  "status",                        default: 0,     null: false
    t.boolean  "cancelled",                     default: false, null: false
    t.boolean  "offered",                       default: false, null: false
    t.integer  "vat_in_cents",                  default: 0,     null: false
    t.string   "vat_currency",                  default: "CHF", null: false
    t.float    "vat_percentage"
    t.text     "conditions"
    t.integer  "condition_id"
  end

  add_index "invoices", ["affair_id"], name: "index_invoices_on_affair_id", using: :btree
  add_index "invoices", ["condition_id"], name: "index_invoices_on_condition_id", using: :btree
  add_index "invoices", ["created_at"], name: "index_invoices_on_created_at", using: :btree
  add_index "invoices", ["invoice_template_id"], name: "index_invoices_on_invoice_template_id", using: :btree
  add_index "invoices", ["pdf_updated_at"], name: "index_invoices_on_pdf_updated_at", using: :btree
  add_index "invoices", ["status"], name: "index_invoices_on_status", using: :btree
  add_index "invoices", ["updated_at"], name: "index_invoices_on_updated_at", using: :btree
  add_index "invoices", ["value_currency"], name: "index_invoices_on_value_currency", using: :btree
  add_index "invoices", ["value_in_cents"], name: "index_invoices_on_value_in_cents", using: :btree
  add_index "invoices", ["vat_in_cents"], name: "index_invoices_on_vat_in_cents", using: :btree

  create_table "jobs", force: true do |t|
    t.string "name",        default: ""
    t.text   "description", default: ""
  end

  add_index "jobs", ["name"], name: "index_jobs_on_name", using: :btree

  create_table "languages", force: true do |t|
    t.string "name", default: ""
    t.string "code", default: ""
  end

  add_index "languages", ["code"], name: "index_languages_on_code", using: :btree
  add_index "languages", ["name"], name: "index_languages_on_name", using: :btree

  create_table "ldap_attributes", force: true do |t|
    t.string   "name",       null: false
    t.string   "mapping",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ldap_attributes", ["name"], name: "index_ldap_attributes_on_name", using: :btree

  create_table "locations", force: true do |t|
    t.integer "parent_id"
    t.string  "name",               default: ""
    t.string  "iso_code_a2",        default: ""
    t.string  "iso_code_a3",        default: ""
    t.string  "iso_code_num",       default: ""
    t.string  "postal_code_prefix", default: ""
    t.string  "phone_prefix",       default: ""
  end

  add_index "locations", ["iso_code_a2"], name: "index_locations_on_iso_code_a2", using: :btree
  add_index "locations", ["iso_code_a3"], name: "index_locations_on_iso_code_a3", using: :btree
  add_index "locations", ["name"], name: "index_locations_on_name", using: :btree
  add_index "locations", ["parent_id"], name: "index_locations_on_parent_id", using: :btree
  add_index "locations", ["postal_code_prefix"], name: "index_locations_on_postal_code_prefix", using: :btree

  create_table "logs", force: true do |t|
    t.integer  "person_id"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.string   "action"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "logs", ["created_at"], name: "index_logs_on_created_at", using: :btree
  add_index "logs", ["person_id"], name: "index_logs_on_person_id", using: :btree
  add_index "logs", ["resource_id"], name: "index_logs_on_resource_id", using: :btree
  add_index "logs", ["resource_type"], name: "index_logs_on_resource_type", using: :btree
  add_index "logs", ["updated_at"], name: "index_logs_on_updated_at", using: :btree

  create_table "people", force: true do |t|
    t.integer  "job_id"
    t.integer  "location_id"
    t.integer  "main_communication_language_id"
    t.boolean  "is_an_organization",                         default: false, null: false
    t.string   "organization_name",                          default: ""
    t.string   "title",                                      default: ""
    t.string   "first_name",                                 default: ""
    t.string   "last_name",                                  default: ""
    t.string   "phone",                                      default: ""
    t.string   "second_phone",                               default: ""
    t.string   "mobile",                                     default: ""
    t.string   "email",                                      default: "",    null: false
    t.string   "second_email",                               default: ""
    t.text     "address",                                    default: ""
    t.date     "birth_date"
    t.string   "nationality",                                default: ""
    t.string   "avs_number",                                 default: ""
    t.text     "bank_informations",                          default: ""
    t.string   "encrypted_password",             limit: 128, default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                              default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.integer  "failed_attempts",                            default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "hidden",                                     default: false, null: false
    t.boolean  "gender"
    t.integer  "task_rate_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "website"
    t.string   "alias_name",                                 default: ""
    t.string   "fax_number",                                 default: ""
    t.string   "creditor_account"
    t.string   "creditor_transitional_account"
    t.string   "creditor_vat_account"
    t.string   "creditor_vat_discount_account"
    t.string   "creditor_discount_account"
  end

  add_index "people", ["authentication_token"], name: "index_people_on_authentication_token", unique: true, using: :btree
  add_index "people", ["created_at"], name: "index_people_on_created_at", using: :btree
  add_index "people", ["email"], name: "index_people_on_email", using: :btree
  add_index "people", ["fax_number"], name: "index_people_on_fax_number", using: :btree
  add_index "people", ["first_name", "last_name"], name: "index_people_on_first_name_and_last_name", using: :btree
  add_index "people", ["first_name"], name: "index_people_on_first_name", using: :btree
  add_index "people", ["gender"], name: "index_people_on_gender", using: :btree
  add_index "people", ["hidden"], name: "index_people_on_hidden", using: :btree
  add_index "people", ["is_an_organization"], name: "index_people_on_is_an_organization", using: :btree
  add_index "people", ["job_id"], name: "index_people_on_job_id", using: :btree
  add_index "people", ["last_name"], name: "index_people_on_last_name", using: :btree
  add_index "people", ["location_id"], name: "index_people_on_location_id", using: :btree
  add_index "people", ["main_communication_language_id"], name: "index_people_on_main_communication_language_id", using: :btree
  add_index "people", ["organization_name"], name: "index_people_on_organization_name", using: :btree
  add_index "people", ["reset_password_token"], name: "index_people_on_reset_password_token", unique: true, using: :btree
  add_index "people", ["second_email"], name: "index_people_on_second_email", using: :btree
  add_index "people", ["task_rate_id"], name: "index_people_on_task_rate_id", using: :btree
  add_index "people", ["unlock_token"], name: "index_people_on_unlock_token", unique: true, using: :btree
  add_index "people", ["updated_at"], name: "index_people_on_updated_at", using: :btree

  create_table "people_communication_languages", id: false, force: true do |t|
    t.integer "person_id"
    t.integer "language_id"
  end

  add_index "people_communication_languages", ["language_id"], name: "people_language_id_index", using: :btree
  add_index "people_communication_languages", ["person_id", "language_id"], name: "people_communication_languages_index", using: :btree
  add_index "people_communication_languages", ["person_id"], name: "people_person_id_index", using: :btree

  create_table "people_private_tags", id: false, force: true do |t|
    t.integer "person_id"
    t.integer "private_tag_id"
  end

  add_index "people_private_tags", ["person_id"], name: "index_people_private_tags_on_person_id", using: :btree
  add_index "people_private_tags", ["private_tag_id"], name: "index_people_private_tags_on_private_tag_id", using: :btree

  create_table "people_public_tags", id: false, force: true do |t|
    t.integer "person_id"
    t.integer "public_tag_id"
  end

  add_index "people_public_tags", ["person_id"], name: "index_people_public_tags_on_person_id", using: :btree
  add_index "people_public_tags", ["public_tag_id"], name: "index_people_public_tags_on_public_tag_id", using: :btree

  create_table "people_roles", id: false, force: true do |t|
    t.integer "person_id"
    t.integer "role_id"
  end

  add_index "people_roles", ["person_id", "role_id"], name: "index_people_roles_on_person_id_and_role_id", using: :btree
  add_index "people_roles", ["person_id"], name: "index_people_roles_on_person_id", using: :btree
  add_index "people_roles", ["role_id"], name: "index_people_roles_on_role_id", using: :btree

  create_table "permissions", force: true do |t|
    t.integer  "role_id"
    t.string   "action",          default: ""
    t.string   "subject",         default: ""
    t.text     "hash_conditions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["action"], name: "index_permissions_on_action", using: :btree
  add_index "permissions", ["role_id"], name: "index_permissions_on_role_id", using: :btree
  add_index "permissions", ["subject"], name: "index_permissions_on_subject", using: :btree

  create_table "private_tags", force: true do |t|
    t.integer "parent_id"
    t.string  "name",      default: "", null: false
    t.string  "color"
  end

  add_index "private_tags", ["name"], name: "index_private_tags_on_name", using: :btree
  add_index "private_tags", ["parent_id"], name: "index_private_tags_on_parent_id", using: :btree

  create_table "product_items", force: true do |t|
    t.integer  "parent_id"
    t.integer  "affair_id"
    t.integer  "product_id"
    t.integer  "program_id"
    t.float    "position"
    t.float    "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "bid_percentage"
    t.integer  "value_in_cents", default: 0,     null: false
    t.string   "value_currency", default: "CHF", null: false
    t.integer  "category_id"
    t.text     "comment"
    t.datetime "ordered_at"
    t.datetime "confirmed_at"
    t.datetime "delivery_at"
    t.date     "warranty_begin"
    t.date     "warranty_end"
  end

  add_index "product_items", ["affair_id", "product_id", "position"], name: "affairs_products_programs_unique_position", using: :btree
  add_index "product_items", ["affair_id"], name: "index_product_items_on_affair_id", using: :btree
  add_index "product_items", ["category_id"], name: "index_product_items_on_category_id", using: :btree
  add_index "product_items", ["confirmed_at"], name: "index_product_items_on_confirmed_at", using: :btree
  add_index "product_items", ["delivery_at"], name: "index_product_items_on_delivery_at", using: :btree
  add_index "product_items", ["ordered_at"], name: "index_product_items_on_ordered_at", using: :btree
  add_index "product_items", ["parent_id"], name: "index_product_items_on_parent_id", using: :btree
  add_index "product_items", ["product_id"], name: "index_product_items_on_product_id", using: :btree
  add_index "product_items", ["program_id"], name: "index_product_items_on_program_id", using: :btree

  create_table "product_programs", force: true do |t|
    t.string   "key",                           null: false
    t.string   "program_group",                 null: false
    t.string   "title"
    t.text     "description"
    t.boolean  "archive",       default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_programs", ["archive"], name: "index_product_programs_on_archive", using: :btree
  add_index "product_programs", ["key"], name: "index_product_programs_on_key", using: :btree
  add_index "product_programs", ["program_group"], name: "index_product_programs_on_program_group", using: :btree
  add_index "product_programs", ["title"], name: "index_product_programs_on_title", using: :btree

  create_table "product_variants", force: true do |t|
    t.integer  "product_id",                             null: false
    t.string   "program_group",                          null: false
    t.string   "title"
    t.integer  "buying_price_in_cents"
    t.string   "buying_price_currency",  default: "CHF", null: false
    t.integer  "selling_price_in_cents",                 null: false
    t.string   "selling_price_currency", default: "CHF"
    t.integer  "art_in_cents"
    t.string   "art_currency",           default: "CHF"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vat_in_cents",           default: 0,     null: false
    t.string   "vat_currency",           default: "CHF", null: false
    t.integer  "vat_percentage"
  end

  add_index "product_variants", ["art_in_cents"], name: "index_product_variants_on_art_in_cents", using: :btree
  add_index "product_variants", ["buying_price_in_cents"], name: "index_product_variants_on_buying_price_in_cents", using: :btree
  add_index "product_variants", ["product_id"], name: "index_product_variants_on_product_id", using: :btree
  add_index "product_variants", ["program_group"], name: "index_product_variants_on_program_group", using: :btree
  add_index "product_variants", ["selling_price_in_cents"], name: "index_product_variants_on_selling_price_in_cents", using: :btree
  add_index "product_variants", ["vat_in_cents"], name: "index_product_variants_on_vat_in_cents", using: :btree

  create_table "products", force: true do |t|
    t.integer  "provider_id"
    t.integer  "after_sale_id"
    t.string   "key",                                null: false
    t.string   "title"
    t.string   "category"
    t.text     "description"
    t.boolean  "has_accessories",    default: false, null: false
    t.boolean  "archive",            default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unit_symbol"
    t.integer  "price_to_unit_rate"
    t.integer  "width"
    t.integer  "height"
    t.integer  "depth"
    t.integer  "volume"
    t.integer  "weight"
  end

  add_index "products", ["after_sale_id"], name: "index_products_on_after_sale_id", using: :btree
  add_index "products", ["category"], name: "index_products_on_category", using: :btree
  add_index "products", ["has_accessories"], name: "index_products_on_has_accessories", using: :btree
  add_index "products", ["key"], name: "index_products_on_key", using: :btree
  add_index "products", ["provider_id"], name: "index_products_on_provider_id", using: :btree
  add_index "products", ["title"], name: "index_products_on_title", using: :btree

  create_table "public_tags", force: true do |t|
    t.integer "parent_id"
    t.string  "name",      default: "", null: false
    t.string  "color"
  end

  add_index "public_tags", ["name"], name: "index_public_tags_on_name", using: :btree
  add_index "public_tags", ["parent_id"], name: "index_public_tags_on_parent_id", using: :btree

  create_table "query_presets", force: true do |t|
    t.string "name",  default: ""
    t.text   "query", default: ""
  end

  add_index "query_presets", ["name"], name: "index_query_presets_on_name", using: :btree
  add_index "query_presets", ["query"], name: "index_query_presets_on_query", using: :btree

  create_table "receipts", force: true do |t|
    t.integer  "invoice_id"
    t.integer  "value_in_cents",   limit: 8
    t.string   "value_currency"
    t.date     "value_date"
    t.string   "means_of_payment",           default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "receipts", ["created_at"], name: "index_receipts_on_created_at", using: :btree
  add_index "receipts", ["invoice_id"], name: "index_receipts_on_invoice_id", using: :btree
  add_index "receipts", ["means_of_payment"], name: "index_receipts_on_means_of_payment", using: :btree
  add_index "receipts", ["updated_at"], name: "index_receipts_on_updated_at", using: :btree
  add_index "receipts", ["value_currency"], name: "index_receipts_on_value_currency", using: :btree
  add_index "receipts", ["value_date"], name: "index_receipts_on_value_date", using: :btree
  add_index "receipts", ["value_in_cents"], name: "index_receipts_on_value_in_cents", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name",        default: ""
    t.text     "description", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "salaries", force: true do |t|
    t.integer  "parent_id"
    t.integer  "person_id",                                                             null: false
    t.date     "from"
    t.date     "to"
    t.string   "title",                                                                 null: false
    t.boolean  "is_reference",                                          default: false, null: false
    t.boolean  "married",                                               default: false, null: false
    t.integer  "children_count",                                        default: 0,     null: false
    t.integer  "yearly_salary_in_cents",                      limit: 8
    t.integer  "yearly_salary_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "generic_template_id",                                                   null: false
    t.string   "pdf_file_name"
    t.string   "pdf_content_type"
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.integer  "activity_rate"
    t.boolean  "paid",                                                  default: false
    t.string   "brut_account"
    t.string   "net_account"
    t.integer  "cert_transport_in_cents",                     limit: 8, default: 0,     null: false
    t.string   "cert_transport_currency",                               default: "CHF", null: false
    t.integer  "cert_food_in_cents",                          limit: 8, default: 0,     null: false
    t.string   "cert_food_currency",                                    default: "CHF", null: false
    t.integer  "cert_logding_in_cents",                       limit: 8, default: 0,     null: false
    t.string   "cert_logding_currency",                                 default: "CHF", null: false
    t.integer  "cert_misc_salary_car_in_cents",               limit: 8, default: 0,     null: false
    t.string   "cert_misc_salary_car_currency",                         default: "CHF", null: false
    t.string   "cert_misc_salary_other_title",                          default: "",    null: false
    t.integer  "cert_misc_salary_other_value_in_cents",       limit: 8, default: 0,     null: false
    t.string   "cert_misc_salary_other_value_currency",                 default: "CHF", null: false
    t.string   "cert_non_periodic_title",                               default: "",    null: false
    t.integer  "cert_non_periodic_value_in_cents",            limit: 8, default: 0,     null: false
    t.string   "cert_non_periodic_value_currency",                      default: "CHF", null: false
    t.string   "cert_capital_title",                                    default: "",    null: false
    t.integer  "cert_capital_value_in_cents",                 limit: 8, default: 0,     null: false
    t.string   "cert_capital_value_currency",                           default: "CHF", null: false
    t.integer  "cert_participation_in_cents",                 limit: 8, default: 0,     null: false
    t.string   "cert_participation_currency",                           default: "CHF", null: false
    t.integer  "cert_compentation_admin_members_in_cents",    limit: 8, default: 0,     null: false
    t.string   "cert_compentation_admin_members_currency",              default: "CHF", null: false
    t.string   "cert_misc_other_title",                                 default: "",    null: false
    t.integer  "cert_misc_other_value_in_cents",              limit: 8, default: 0,     null: false
    t.string   "cert_misc_other_value_currency",                        default: "CHF", null: false
    t.integer  "cert_avs_ac_aanp_in_cents",                   limit: 8, default: 0,     null: false
    t.string   "cert_avs_ac_aanp_currency",                             default: "CHF", null: false
    t.integer  "cert_lpp_in_cents",                           limit: 8, default: 0,     null: false
    t.string   "cert_lpp_currency",                                     default: "CHF", null: false
    t.integer  "cert_buy_lpp_in_cents",                       limit: 8, default: 0,     null: false
    t.string   "cert_buy_lpp_currency",                                 default: "CHF", null: false
    t.integer  "cert_is_in_cents",                            limit: 8, default: 0,     null: false
    t.string   "cert_is_currency",                                      default: "CHF", null: false
    t.integer  "cert_alloc_traveling_in_cents",               limit: 8, default: 0,     null: false
    t.string   "cert_alloc_traveling_currency",                         default: "CHF", null: false
    t.integer  "cert_alloc_food_in_cents",                    limit: 8, default: 0,     null: false
    t.string   "cert_alloc_food_currency",                              default: "CHF", null: false
    t.string   "cert_alloc_other_actual_cost_title",                    default: "",    null: false
    t.integer  "cert_alloc_other_actual_cost_value_in_cents", limit: 8, default: 0,     null: false
    t.string   "cert_alloc_other_actual_cost_value_currency",           default: "CHF", null: false
    t.integer  "cert_alloc_representation_in_cents",          limit: 8, default: 0,     null: false
    t.string   "cert_alloc_representation_currency",                    default: "CHF", null: false
    t.integer  "cert_alloc_car_in_cents",                     limit: 8, default: 0,     null: false
    t.string   "cert_alloc_car_currency",                               default: "CHF", null: false
    t.string   "cert_alloc_other_fixed_fees_title",                     default: "",    null: false
    t.integer  "cert_alloc_other_fixed_fees_value_in_cents",  limit: 8, default: 0,     null: false
    t.string   "cert_alloc_other_fixed_fees_value_currency",            default: "CHF", null: false
    t.integer  "cert_formation_in_cents",                     limit: 8, default: 0,     null: false
    t.string   "cert_formation_currency",                               default: "CHF", null: false
    t.string   "cert_others_title",                                     default: "",    null: false
    t.text     "cert_notes",                                            default: "",    null: false
    t.string   "employer_account",                                      default: ""
    t.string   "yearly_salary_currency",                                default: "CHF", null: false
    t.text     "comments"
  end

  add_index "salaries", ["is_reference"], name: "index_salaries_on_is_template", using: :btree
  add_index "salaries", ["paid"], name: "index_salaries_on_paid", using: :btree
  add_index "salaries", ["parent_id"], name: "index_salaries_on_parent_id", using: :btree
  add_index "salaries", ["person_id"], name: "index_salaries_on_person_id", using: :btree

  create_table "salaries_items", force: true do |t|
    t.integer  "parent_id"
    t.integer  "salary_id",                                null: false
    t.integer  "position",                                 null: false
    t.string   "title",                                    null: false
    t.integer  "value_in_cents", limit: 8,                 null: false
    t.string   "category"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "value_currency",           default: "CHF", null: false
  end

  add_index "salaries_items", ["salary_id"], name: "index_salaries_items_on_salary_id", using: :btree

  create_table "salaries_items_taxes", id: false, force: true do |t|
    t.integer "item_id", null: false
    t.integer "tax_id",  null: false
  end

  add_index "salaries_items_taxes", ["item_id"], name: "index_salaries_items_taxes_on_item_id", using: :btree
  add_index "salaries_items_taxes", ["tax_id"], name: "index_salaries_items_taxes_on_tax_id", using: :btree

  create_table "salaries_tax_data", force: true do |t|
    t.integer  "salary_id",                                                                 null: false
    t.integer  "tax_id",                                                                    null: false
    t.integer  "position",                                                                  null: false
    t.integer  "employer_value_in_cents", limit: 8,                                         null: false
    t.decimal  "employer_percent",                  precision: 6, scale: 3,                 null: false
    t.boolean  "employer_use_percent",                                                      null: false
    t.integer  "employee_value_in_cents", limit: 8,                                         null: false
    t.decimal  "employee_percent",                  precision: 6, scale: 3,                 null: false
    t.boolean  "employee_use_percent",                                                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "employee_value_currency",                                   default: "CHF", null: false
    t.string   "employer_value_currency",                                   default: "CHF", null: false
  end

  add_index "salaries_tax_data", ["salary_id"], name: "index_salaries_tax_data_on_salary_id", using: :btree
  add_index "salaries_tax_data", ["tax_id"], name: "index_salaries_tax_data_on_tax_id", using: :btree

  create_table "salaries_taxes", force: true do |t|
    t.string   "title",                              null: false
    t.string   "model",                              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "employee_account"
    t.boolean  "exporter_avs_group", default: false, null: false
    t.boolean  "exporter_lpp_group", default: false, null: false
    t.boolean  "exporter_is_group",  default: false, null: false
    t.string   "employer_account",   default: ""
    t.boolean  "archive",            default: false, null: false
  end

  add_index "salaries_taxes", ["exporter_avs_group"], name: "index_salaries_taxes_on_exporter_avs_group", using: :btree
  add_index "salaries_taxes", ["exporter_is_group"], name: "index_salaries_taxes_on_exporter_is_group", using: :btree
  add_index "salaries_taxes", ["exporter_lpp_group"], name: "index_salaries_taxes_on_exporter_lpp_group", using: :btree

  create_table "salaries_taxes_age", force: true do |t|
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
  end

  add_index "salaries_taxes_age", ["tax_id"], name: "index_salaries_taxes_age_on_tax_id", using: :btree
  add_index "salaries_taxes_age", ["year"], name: "index_salaries_taxes_age_on_year", using: :btree

  create_table "salaries_taxes_generic", force: true do |t|
    t.integer  "tax_id",                                                                    null: false
    t.integer  "year",                                                                      null: false
    t.integer  "salary_from_in_cents",    limit: 8
    t.integer  "salary_to_in_cents",      limit: 8
    t.integer  "employer_value_in_cents", limit: 8,                                         null: false
    t.decimal  "employer_percent",                  precision: 6, scale: 3,                 null: false
    t.boolean  "employer_use_percent",                                                      null: false
    t.integer  "employee_value_in_cents", limit: 8,                                         null: false
    t.decimal  "employee_percent",                  precision: 6, scale: 3,                 null: false
    t.boolean  "employee_use_percent",                                                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salary_from_currency",                                      default: "CHF", null: false
    t.string   "salary_to_currency",                                        default: "CHF", null: false
    t.string   "employer_value_currency",                                   default: "CHF", null: false
    t.string   "employee_value_currency",                                   default: "CHF", null: false
  end

  add_index "salaries_taxes_generic", ["tax_id"], name: "index_salaries_taxes_generic_on_tax_id", using: :btree
  add_index "salaries_taxes_generic", ["year"], name: "index_salaries_taxes_generic_on_year", using: :btree

  create_table "salaries_taxes_is", force: true do |t|
    t.integer  "tax_id",                                                                  null: false
    t.integer  "year",                                                                    null: false
    t.integer  "yearly_from_in_cents",  limit: 8,                                         null: false
    t.integer  "yearly_to_in_cents",    limit: 8,                                         null: false
    t.integer  "monthly_from_in_cents", limit: 8,                                         null: false
    t.integer  "monthly_to_in_cents",   limit: 8,                                         null: false
    t.integer  "hourly_from_in_cents",  limit: 8,                                         null: false
    t.integer  "hourly_to_in_cents",    limit: 8,                                         null: false
    t.decimal  "percent_alone",                   precision: 7, scale: 2
    t.decimal  "percent_married",                 precision: 7, scale: 2
    t.decimal  "percent_children_1",              precision: 7, scale: 2
    t.decimal  "percent_children_2",              precision: 7, scale: 2
    t.decimal  "percent_children_3",              precision: 7, scale: 2
    t.decimal  "percent_children_4",              precision: 7, scale: 2
    t.decimal  "percent_children_5",              precision: 7, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "yearly_from_currency",                                    default: "CHF", null: false
    t.string   "yearly_to_currency",                                      default: "CHF", null: false
    t.string   "monthly_from_currency",                                   default: "CHF", null: false
    t.string   "monthly_to_currency",                                     default: "CHF", null: false
    t.string   "hourly_from_currency",                                    default: "CHF", null: false
    t.string   "hourly_to_currency",                                      default: "CHF", null: false
  end

  add_index "salaries_taxes_is", ["tax_id"], name: "index_salaries_taxes_is_on_tax_id", using: :btree
  add_index "salaries_taxes_is", ["year"], name: "index_salaries_taxes_is_on_year", using: :btree

  create_table "salaries_taxes_is2014", force: true do |t|
    t.integer  "tax_id",                               null: false
    t.integer  "year",                                 null: false
    t.string   "tax_group",                            null: false
    t.integer  "children_count",                       null: false
    t.string   "ecclesiastical",       default: "N",   null: false
    t.integer  "salary_from_in_cents", default: 0,     null: false
    t.string   "salary_from_currency", default: "CHF", null: false
    t.integer  "salary_to_in_cents",   default: 0,     null: false
    t.string   "salary_to_currency",   default: "CHF", null: false
    t.integer  "tax_value_in_cents",   default: 0,     null: false
    t.string   "tax_value_currency",   default: "CHF", null: false
    t.float    "tax_value_percentage", default: 0.0,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "salaries_taxes_is2014", ["tax_id"], name: "index_salaries_taxes_is2014_on_tax_id", using: :btree
  add_index "salaries_taxes_is2014", ["year"], name: "index_salaries_taxes_is2014_on_year", using: :btree

  create_table "search_attributes", force: true do |t|
    t.string "model",    default: "", null: false
    t.string "name",     default: "", null: false
    t.text   "indexing", default: "", null: false
    t.text   "mapping",  default: "", null: false
    t.string "group",    default: ""
  end

  add_index "search_attributes", ["group"], name: "index_search_attributes_on_group", using: :btree
  add_index "search_attributes", ["model"], name: "index_search_attributes_on_model", using: :btree
  add_index "search_attributes", ["name"], name: "index_search_attributes_on_name", using: :btree

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "subscription_values", force: true do |t|
    t.integer "subscription_id",                     null: false
    t.integer "invoice_template_id",                 null: false
    t.integer "private_tag_id"
    t.integer "value_in_cents",      default: 0
    t.string  "value_currency",      default: "CHF"
    t.integer "position",                            null: false
  end

  add_index "subscription_values", ["position"], name: "index_subscription_values_on_position", using: :btree
  add_index "subscription_values", ["private_tag_id"], name: "index_subscription_values_on_private_tag_id", using: :btree
  add_index "subscription_values", ["subscription_id"], name: "index_subscription_values_on_subscription_id", using: :btree
  add_index "subscription_values", ["value_currency"], name: "index_subscription_values_on_value_currency", using: :btree
  add_index "subscription_values", ["value_in_cents"], name: "index_subscription_values_on_value_in_cents", using: :btree

  create_table "subscriptions", force: true do |t|
    t.string   "title",                     default: "", null: false
    t.text     "description",               default: ""
    t.date     "interval_starts_on"
    t.date     "interval_ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pdf_file_name"
    t.string   "pdf_content_type"
    t.integer  "pdf_file_size"
    t.datetime "pdf_updated_at"
    t.text     "last_pdf_generation_query"
    t.integer  "parent_id"
  end

  add_index "subscriptions", ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
  add_index "subscriptions", ["interval_ends_on"], name: "index_subscriptions_on_interval_ends_on", using: :btree
  add_index "subscriptions", ["interval_starts_on"], name: "index_subscriptions_on_interval_starts_on", using: :btree
  add_index "subscriptions", ["parent_id"], name: "index_subscriptions_on_parent_id", using: :btree
  add_index "subscriptions", ["pdf_updated_at"], name: "index_subscriptions_on_pdf_updated_at", using: :btree
  add_index "subscriptions", ["updated_at"], name: "index_subscriptions_on_updated_at", using: :btree

  create_table "task_presets", force: true do |t|
    t.integer "task_type_id"
    t.string  "title",          default: "", null: false
    t.text    "description",    default: ""
    t.float   "duration"
    t.integer "value_in_cents"
    t.string  "value_currency"
  end

  add_index "task_presets", ["task_type_id"], name: "index_task_presets_on_task_type_id", using: :btree
  add_index "task_presets", ["title"], name: "index_task_presets_on_title", using: :btree
  add_index "task_presets", ["value_currency"], name: "index_task_presets_on_value_currency", using: :btree
  add_index "task_presets", ["value_in_cents"], name: "index_task_presets_on_value_in_cents", using: :btree

  create_table "task_rates", force: true do |t|
    t.string   "title",                          null: false
    t.text     "description"
    t.integer  "value_in_cents",                 null: false
    t.string   "value_currency", default: "CHF"
    t.boolean  "archive",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "task_rates", ["archive"], name: "index_task_rates_on_archive", using: :btree
  add_index "task_rates", ["value_currency"], name: "index_task_rates_on_value_currency", using: :btree
  add_index "task_rates", ["value_in_cents"], name: "index_task_rates_on_value_in_cents", using: :btree

  create_table "task_types", force: true do |t|
    t.string  "title",          default: "",    null: false
    t.text    "description",    default: ""
    t.float   "ratio",                          null: false
    t.integer "value_in_cents"
    t.string  "value_currency", default: "CHF"
    t.boolean "archive",        default: false
  end

  add_index "task_types", ["archive"], name: "index_task_types_on_archive", using: :btree
  add_index "task_types", ["title"], name: "index_task_types_on_title", using: :btree
  add_index "task_types", ["value_currency"], name: "index_task_types_on_value_currency", using: :btree
  add_index "task_types", ["value_in_cents"], name: "index_task_types_on_value_in_cents", using: :btree

  create_table "tasks", force: true do |t|
    t.integer  "executer_id",                              null: false
    t.text     "description",              default: ""
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "affair_id",                                null: false
    t.integer  "task_type_id",                             null: false
    t.integer  "value_in_cents", limit: 8, default: 0,     null: false
    t.string   "value_currency",           default: "CHF", null: false
    t.integer  "salary_id"
    t.datetime "start_date"
    t.integer  "creator_id"
  end

  add_index "tasks", ["affair_id"], name: "index_tasks_on_affair_id", using: :btree
  add_index "tasks", ["creator_id"], name: "index_tasks_on_creator_id", using: :btree
  add_index "tasks", ["duration"], name: "index_tasks_on_duration", using: :btree
  add_index "tasks", ["executer_id"], name: "index_tasks_on_executer_id", using: :btree
  add_index "tasks", ["salary_id"], name: "index_tasks_on_salary_id", using: :btree
  add_index "tasks", ["start_date"], name: "index_tasks_on_start_date", using: :btree
  add_index "tasks", ["task_type_id"], name: "index_tasks_on_task_type_id", using: :btree
  add_index "tasks", ["value_currency"], name: "index_tasks_on_value_currency", using: :btree
  add_index "tasks", ["value_in_cents"], name: "index_tasks_on_value_in_cents", using: :btree

end
