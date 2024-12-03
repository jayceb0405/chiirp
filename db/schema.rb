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

ActiveRecord::Schema[7.2].define(version: 2024_11_13_194045) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "affiliates", force: :cascade do |t|
    t.string "company_name"
    t.string "contact_name"
    t.string "contact_phone"
    t.string "contact_email"
    t.decimal "commission", default: "0.0", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "aiagent_messages", force: :cascade do |t|
    t.bigint "aiagent_session_id", null: false
    t.bigint "message_id"
    t.string "role", null: false
    t.text "content"
    t.string "function_name"
    t.jsonb "function_params", default: {}, null: false
    t.jsonb "raw_post", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aiagent_session_id"], name: "index_aiagent_messages_on_aiagent_session_id"
    t.index ["function_params"], name: "index_aiagent_messages_on_function_params", using: :gin
    t.index ["message_id"], name: "index_aiagent_messages_on_message_id"
    t.index ["raw_post"], name: "index_aiagent_messages_on_raw_post", using: :gin
  end

  create_table "aiagent_sessions", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "aiagent_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "aiagent_type", default: "gpt-4o-mini", null: false
    t.string "type", default: "Aiagent::SmsSession", null: false
    t.integer "ended_reason", default: 0, null: false
    t.string "from_phone"
    t.index ["aiagent_id"], name: "index_aiagent_sessions_on_aiagent_id"
    t.index ["contact_id", "aiagent_id", "ended_at"], name: "contact_aiagent_ended_at_index", unique: true
    t.index ["contact_id", "started_at", "ended_at"], name: "active_aiagent_sessions"
    t.index ["data"], name: "index_aiagent_sessions_on_data", using: :gin
    t.index ["ended_at"], name: "index_aiagent_sessions_on_ended_at"
    t.index ["type"], name: "index_aiagent_sessions_on_type"
  end

  create_table "aiagents", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "campaign_id"
    t.bigint "group_id"
    t.bigint "tag_id"
    t.bigint "stage_id"
    t.string "name"
    t.text "system_prompt"
    t.string "initial_prompt"
    t.string "ending_prompt"
    t.string "action"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "share_code", default: "", null: false
    t.integer "max_messages", default: 0, null: false
    t.string "max_messages_prompt"
    t.bigint "help_campaign_id"
    t.bigint "help_group_id"
    t.bigint "help_tag_id"
    t.bigint "help_stage_id"
    t.string "aiagent_type", default: "gpt-4o-mini"
    t.boolean "show_ai", default: true, null: false
    t.integer "session_length", default: 0, null: false
    t.bigint "session_length_campaign_id"
    t.bigint "session_length_group_id"
    t.bigint "session_length_tag_id"
    t.bigint "session_length_stage_id"
    t.bigint "stop_campaign_ids", array: true
    t.bigint "help_stop_campaign_ids", array: true
    t.bigint "session_length_stop_campaign_ids", array: true
    t.index ["campaign_id"], name: "index_aiagents_on_campaign_id"
    t.index ["client_id"], name: "index_aiagents_on_client_id"
    t.index ["data"], name: "index_aiagents_on_data", using: :gin
    t.index ["group_id"], name: "index_aiagents_on_group_id"
    t.index ["help_campaign_id"], name: "index_aiagents_on_help_campaign_id"
    t.index ["help_group_id"], name: "index_aiagents_on_help_group_id"
    t.index ["help_stage_id"], name: "index_aiagents_on_help_stage_id"
    t.index ["help_tag_id"], name: "index_aiagents_on_help_tag_id"
    t.index ["session_length_campaign_id"], name: "index_aiagents_on_session_length_campaign_id"
    t.index ["session_length_group_id"], name: "index_aiagents_on_session_length_group_id"
    t.index ["session_length_stage_id"], name: "index_aiagents_on_session_length_stage_id"
    t.index ["session_length_tag_id"], name: "index_aiagents_on_session_length_tag_id"
    t.index ["share_code"], name: "index_aiagents_on_share_code", unique: true
    t.index ["stage_id"], name: "index_aiagents_on_stage_id"
    t.index ["tag_id"], name: "index_aiagents_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "campaign_groups", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.boolean "marketplace", default: false, null: false
    t.boolean "marketplace_ok", default: false, null: false
    t.integer "price", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_campaign_groups_on_client_id"
  end

  create_table "campaign_share_codes", force: :cascade do |t|
    t.bigint "campaign_id"
    t.bigint "campaign_group_id"
    t.string "share_code", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["campaign_group_id"], name: "index_campaign_share_codes_on_campaign_group_id"
    t.index ["campaign_id"], name: "index_campaign_share_codes_on_campaign_id"
    t.index ["share_code"], name: "index_campaign_share_codes_on_share_code"
  end

  create_table "campaigns", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name"
    t.boolean "active", default: true
    t.boolean "allow_repeat", default: true
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "default_phone", default: "", null: false
    t.integer "campaign_group_id", default: 0, null: false
    t.boolean "marketplace", default: false, null: false
    t.boolean "marketplace_ok", default: false, null: false
    t.decimal "price", default: "0.0", null: false
    t.jsonb "data", default: {}, null: false
    t.boolean "lock_phone", default: false, null: false
    t.boolean "analyzed", default: false, null: false
    t.datetime "last_started_at"
    t.index ["campaign_group_id"], name: "index_campaigns_on_campaign_group_id"
    t.index ["client_id"], name: "index_campaigns_on_client_id"
    t.index ["name"], name: "index_campaigns_on_name"
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.string "type", limit: 30
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["type"], name: "index_ckeditor_assets_on_type"
  end

  create_table "client_api_calls", force: :cascade do |t|
    t.bigint "client_id"
    t.string "target"
    t.string "client_api_id"
    t.string "api_call"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_api_calls_on_client_id"
  end

  create_table "client_api_integrations", force: :cascade do |t|
    t.bigint "client_id"
    t.string "target", default: "", null: false
    t.string "name", default: "", null: false
    t.string "api_key", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "data", default: {}, null: false
    t.text "metadata"
    t.index ["client_id", "target", "name"], name: "index_client_api_integrations_on_client_id_and_target_and_name"
    t.index ["data"], name: "index_client_api_integrations_on_data", using: :gin
  end

  create_table "client_attachments", force: :cascade do |t|
    t.bigint "client_id"
    t.string "image"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_client_attachments_on_client_id"
  end

  create_table "client_custom_fields", force: :cascade do |t|
    t.bigint "client_id"
    t.string "var_name", default: "", null: false
    t.string "var_var", default: "", null: false
    t.string "var_type", default: "", null: false
    t.string "var_options", default: ""
    t.string "var_placeholder", default: "", null: false
    t.boolean "var_important", default: true, null: false
    t.datetime "created_at", precision: nil, default: "2019-05-29 16:11:38", null: false
    t.datetime "updated_at", precision: nil, default: "2019-05-29 16:11:38", null: false
    t.boolean "image_is_valid", default: false, null: false
    t.index ["client_id"], name: "index_client_custom_fields_on_client_id"
    t.index ["var_var"], name: "index_client_custom_fields_on_var_var"
  end

  create_table "client_dlc10_brands", force: :cascade do |t|
    t.bigint "client_id"
    t.string "tcr_brand_id", default: "", null: false
    t.string "firstname", default: "", null: false
    t.string "lastname", default: "", null: false
    t.string "company_name", default: "", null: false
    t.string "display_name", default: "", null: false
    t.string "street", default: "", null: false
    t.string "city", default: "", null: false
    t.string "state", default: "", null: false
    t.string "zipcode", default: "", null: false
    t.string "country", default: "", null: false
    t.string "phone", default: "", null: false
    t.string "email", default: "", null: false
    t.string "entity_type", default: "", null: false
    t.string "ein", default: "", null: false
    t.string "ein_country", default: "", null: false
    t.string "stock_symbol", default: "", null: false
    t.string "stock_exchange", default: "", null: false
    t.string "ip_address", default: "", null: false
    t.string "website"
    t.string "brand_relationship", default: "", null: false
    t.string "vertical", default: "", null: false
    t.string "alt_business_id", default: "", null: false
    t.string "alt_business_id_type", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "submitted_at"
    t.datetime "resubmitted_at"
    t.datetime "verified_at"
    t.string "support_email"
    t.index ["client_id"], name: "index_client_dlc10_brands_on_client_id"
  end

  create_table "client_dlc10_campaigns", force: :cascade do |t|
    t.bigint "dlc10_brand_id"
    t.string "name", default: "", null: false
    t.string "vertical", default: "", null: false
    t.string "use_case", default: "", null: false
    t.text "sub_use_cases", default: [], array: true
    t.string "reseller_id", default: "", null: false
    t.string "description", default: "", null: false
    t.boolean "embedded_link", default: true, null: false
    t.boolean "embedded_phone", default: false, null: false
    t.boolean "number_pool", default: false, null: false
    t.boolean "age_gated", default: false, null: false
    t.boolean "direct_lending", default: false, null: false
    t.text "sample1", default: "", null: false
    t.text "sample2", default: "", null: false
    t.text "sample3", default: "", null: false
    t.text "sample4", default: "", null: false
    t.text "sample5", default: "", null: false
    t.string "reference_id", default: "", null: false
    t.boolean "auto_renewal", default: true, null: false
    t.boolean "affiliate_marketing", default: false, null: false
    t.decimal "mo_charge", default: "0.0", null: false
    t.date "next_mo_date", default: -> { "now()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "message_flow", default: "", null: false
    t.string "tcr_campaign_id"
    t.string "phone_vendor"
    t.datetime "shared_at"
    t.datetime "accepted_at"
    t.datetime "dca_completed_at"
    t.index ["dlc10_brand_id"], name: "index_client_dlc10_campaigns_on_dlc10_brand_id"
  end

  create_table "client_holidays", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: "", null: false
    t.date "occurs_at"
    t.string "action", default: "after", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_holidays_on_client_id"
  end

  create_table "client_kpis", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: "", null: false
    t.string "criteria_01", default: "", null: false
    t.boolean "c_01_in_period", default: true, null: false
    t.string "criteria_02", default: "", null: false
    t.boolean "c_02_in_period", default: true, null: false
    t.string "operator", default: "/", null: false
    t.string "color", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_kpis_on_client_id"
  end

  create_table "client_notes", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "user_id"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_notes_on_client_id"
    t.index ["user_id"], name: "index_client_notes_on_user_id"
  end

  create_table "client_transactions", force: :cascade do |t|
    t.bigint "client_id"
    t.string "setting_key", default: "", null: false
    t.string "setting_value", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "old_data", default: ""
    t.jsonb "data", default: {}, null: false
    t.index ["client_id"], name: "index_client_transactions_on_client_id"
    t.index ["data"], name: "index_client_transactions_on_data", using: :gin
    t.index ["setting_key"], name: "index_client_transactions_on_setting_key"
  end

  create_table "client_widgets", force: :cascade do |t|
    t.bigint "client_id"
    t.string "widget_name", default: "", null: false
    t.integer "campaign_id", default: 0, null: false
    t.integer "tag_id", default: 0, null: false
    t.string "widget_key", default: "", null: false
    t.string "share_code", default: "", null: false
    t.jsonb "formatting", default: {}, null: false
    t.bigint "group_id", default: 0, null: false
    t.datetime "created_at", precision: nil, default: "2019-05-29 16:11:38", null: false
    t.datetime "updated_at", precision: nil, default: "2019-05-29 16:11:38", null: false
    t.bigint "stage_id", default: 0, null: false
    t.index ["campaign_id"], name: "index_client_widgets_on_campaign_id"
    t.index ["client_id"], name: "index_client_widgets_on_client_id"
    t.index ["formatting"], name: "index_client_widgets_on_formatting", using: :gin
    t.index ["group_id"], name: "index_client_widgets_on_group_id"
    t.index ["stage_id"], name: "index_client_widgets_on_stage_id"
    t.index ["tag_id"], name: "index_client_widgets_on_tag_id"
    t.index ["widget_key"], name: "index_client_widgets_on_widget_key"
  end

  create_table "clients", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "address1", default: "", null: false
    t.string "address2", default: "", null: false
    t.string "city", default: "", null: false
    t.string "state", default: "", null: false
    t.string "zip", default: "", null: false
    t.string "phone", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "time_zone", default: "UTC", null: false
    t.bigint "def_user_id"
    t.integer "current_balance", default: 0, null: false
    t.date "next_pmt_date", default: -> { "now()" }, null: false
    t.jsonb "data", default: {}, null: false
    t.bigint "contact_id", default: 0, null: false
    t.string "tenant", default: "", null: false
    t.string "phone_vendor", default: "bandwidth", null: false
    t.bigint "affiliate_id"
    t.bigint "package_id"
    t.bigint "package_page_id"
    t.index ["affiliate_id"], name: "index_clients_on_affiliate_id"
    t.index ["contact_id"], name: "index_clients_on_contact_id"
    t.index ["data"], name: "index_clients_on_data", using: :gin
    t.index ["def_user_id"], name: "index_clients_on_def_user_id"
    t.index ["name"], name: "index_clients_on_name"
    t.index ["package_id"], name: "index_clients_on_package_id"
    t.index ["package_page_id"], name: "index_clients_on_package_page_id"
    t.index ["tenant"], name: "index_clients_on_tenant"
  end

  create_table "clients_lead_sources", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: "New Lead Source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_clients_lead_sources_on_client_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "commenter"
    t.text "body"
    t.bigint "article_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["article_id"], name: "index_comments_on_article_id"
  end

  create_table "contact_api_integrations", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "target", default: "", null: false
    t.string "name", default: "", null: false
    t.string "api_key", default: "", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_contact_api_integrations_on_contact_id"
    t.index ["data"], name: "index_contact_api_integrations_on_data", using: :gin
  end

  create_table "contact_attachments", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "image"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_contact_attachments_on_contact_id"
  end

  create_table "contact_campaign_triggeractions", force: :cascade do |t|
    t.bigint "contact_campaign_id"
    t.bigint "triggeraction_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "outcome"
    t.index ["contact_campaign_id"], name: "index_contact_campaign_triggeractions_on_contact_campaign_id"
    t.index ["triggeraction_id"], name: "index_contact_campaign_triggeractions_on_triggeraction_id"
  end

  create_table "contact_campaigns", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "campaign_id"
    t.boolean "completed", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "target_time", precision: nil
    t.integer "retry_count", default: 0, null: false
    t.text "data", default: ""
    t.index ["campaign_id"], name: "index_contact_campaigns_on_campaign_id"
    t.index ["completed", "created_at"], name: "index_contact_campaigns_on_completed_and_created_at"
    t.index ["contact_id"], name: "index_contact_campaigns_on_contact_id"
  end

  create_table "contact_custom_fields", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "client_custom_field_id"
    t.string "var_value", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_custom_field_id"], name: "index_contact_custom_fields_on_client_custom_field_id"
    t.index ["contact_id"], name: "index_contact_custom_fields_on_contact_id"
  end

  create_table "contact_estimate_options", force: :cascade do |t|
    t.bigint "estimate_id"
    t.string "name", default: "", null: false
    t.string "status", default: ""
    t.string "option_number", default: "", null: false
    t.decimal "total_amount", default: "0.0", null: false
    t.text "notes", default: "", null: false
    t.text "message", default: "", null: false
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimate_id"], name: "index_contact_estimate_options_on_estimate_id"
    t.index ["ext_id"], name: "index_contact_estimate_options_on_ext_id"
    t.index ["option_number"], name: "index_contact_estimate_options_on_option_number"
  end

  create_table "contact_estimates", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "estimate_number", default: "", null: false
    t.string "status", default: "", null: false
    t.string "address_01", default: "", null: false
    t.string "address_02", default: "", null: false
    t.string "city", default: "", null: false
    t.string "state", default: "", null: false
    t.string "postal_code", default: "", null: false
    t.string "country", default: "", null: false
    t.datetime "scheduled_start_at", precision: nil
    t.datetime "scheduled_end_at", precision: nil
    t.integer "scheduled_arrival_window", default: 0, null: false
    t.datetime "actual_started_at", precision: nil
    t.datetime "actual_completed_at", precision: nil
    t.datetime "actual_on_my_way_at", precision: nil
    t.string "ext_tech_id", default: "", null: false
    t.text "notes", default: "", null: false
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "total_amount", default: "0.0", null: false
    t.decimal "outstanding_balance", default: "0.0", null: false
    t.string "proposal_url", default: "", null: false
    t.string "ext_sales_rep_id", default: "", null: false
    t.datetime "scheduled_arrival_window_start_at"
    t.datetime "scheduled_arrival_window_end_at"
    t.string "customer_type"
    t.bigint "job_id"
    t.index ["contact_id"], name: "index_contact_estimates_on_contact_id"
    t.index ["ext_id"], name: "index_contact_estimates_on_ext_id"
    t.index ["job_id"], name: "index_contact_estimates_on_job_id"
  end

  create_table "contact_ext_references", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "target", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_ext_references_on_contact_id"
    t.index ["target"], name: "index_contact_ext_references_on_target"
  end

  create_table "contact_fb_pages", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "page_id", default: "", null: false
    t.string "page_scoped_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "page_token", default: "", null: false
    t.index ["contact_id"], name: "index_contact_fb_pages_on_contact_id"
    t.index ["page_id"], name: "index_contact_fb_pages_on_page_id"
  end

  create_table "contact_ggl_conversations", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "agent_id", default: "", null: false
    t.string "conversation_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_ggl_conversations_on_contact_id"
  end

  create_table "contact_invoices", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "job_id"
    t.string "ext_source"
    t.string "ext_id"
    t.string "invoice_number"
    t.string "description"
    t.string "customer_type"
    t.string "status"
    t.decimal "total_amount"
    t.decimal "total_payments"
    t.decimal "balance_due"
    t.datetime "due_date"
    t.integer "net"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_invoices_on_contact_id"
    t.index ["ext_id"], name: "index_contact_invoices_on_ext_id"
    t.index ["invoice_number"], name: "index_contact_invoices_on_invoice_number"
    t.index ["job_id"], name: "index_contact_invoices_on_job_id"
  end

  create_table "contact_jobs", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "status", default: "", null: false
    t.text "description", default: "", null: false
    t.string "address_01", default: "", null: false
    t.string "address_02", default: "", null: false
    t.string "city", default: "", null: false
    t.string "state", default: "", null: false
    t.string "postal_code", default: "", null: false
    t.string "country", default: "", null: false
    t.datetime "scheduled_start_at", precision: nil
    t.datetime "scheduled_end_at", precision: nil
    t.integer "scheduled_arrival_window", default: 0, null: false
    t.datetime "actual_started_at", precision: nil
    t.datetime "actual_completed_at", precision: nil
    t.datetime "actual_on_my_way_at", precision: nil
    t.decimal "total_amount", default: "0.0", null: false
    t.decimal "outstanding_balance", default: "0.0", null: false
    t.string "ext_tech_id", default: "", null: false
    t.text "notes", default: "", null: false
    t.string "invoice_number", default: "", null: false
    t.datetime "invoice_date", precision: nil
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "job_type", default: "", null: false
    t.string "ext_sales_rep_id", default: "", null: false
    t.datetime "scheduled_arrival_window_start_at"
    t.datetime "scheduled_arrival_window_end_at"
    t.string "customer_type"
    t.string "ext_invoice_id"
    t.decimal "payments_received", default: "0.0", null: false
    t.string "business_unit_id"
    t.index ["contact_id"], name: "index_contact_jobs_on_contact_id"
    t.index ["ext_id"], name: "index_contact_jobs_on_ext_id"
  end

  create_table "contact_lineitems", force: :cascade do |t|
    t.string "lineitemable_type"
    t.bigint "lineitemable_id"
    t.string "name", default: "", null: false
    t.decimal "total", default: "0.0", null: false
    t.string "ext_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lineitemable_type", "lineitemable_id"], name: "index_lineitems_on_lineitemable_type_and_lineitemable_id"
  end

  create_table "contact_notes", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "user_id"
    t.text "note"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_contact_notes_on_contact_id"
    t.index ["user_id"], name: "index_contact_notes_on_user_id"
  end

  create_table "contact_phones", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "phone", default: "", null: false
    t.string "label", default: "", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_contact_phones_on_contact_id"
    t.index ["phone"], name: "index_contact_phones_on_phone"
  end

  create_table "contact_raw_posts", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_raw_posts_on_contact_id"
    t.index ["ext_id"], name: "index_contact_raw_posts_on_ext_id"
  end

  create_table "contact_requests", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.string "status", default: "", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source"
    t.index ["contact_id"], name: "index_contact_requests_on_contact_id"
    t.index ["ext_id"], name: "index_contact_requests_on_ext_id"
  end

  create_table "contact_subscriptions", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.string "customer_id", default: "", null: false
    t.string "customer_number", default: ""
    t.string "firstname", default: ""
    t.string "lastname", default: ""
    t.string "companyname", default: ""
    t.string "address_01", default: ""
    t.string "address_02", default: ""
    t.string "city", default: ""
    t.string "state", default: ""
    t.string "postal_code", default: ""
    t.string "country", default: ""
    t.decimal "total", default: "0.0", null: false
    t.decimal "total_due", default: "0.0", null: false
    t.string "description", default: ""
    t.datetime "added_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_subscriptions_on_contact_id"
    t.index ["ext_id"], name: "index_contact_subscriptions_on_ext_id"
  end

  create_table "contact_visits", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "job_id"
    t.string "ext_source", default: "", null: false
    t.string "ext_id", default: "", null: false
    t.string "status", default: "", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.string "ext_tech_id", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_type"
    t.index ["contact_id"], name: "index_contact_visits_on_contact_id"
    t.index ["ext_id"], name: "index_contact_visits_on_ext_id"
    t.index ["job_id"], name: "index_contact_visits_on_job_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "email"
    t.bigint "client_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "ok2text", default: "1"
    t.datetime "last_contacted", precision: nil
    t.string "ok2email", default: "1"
    t.string "firstname", default: "", null: false
    t.string "lastname", default: "", null: false
    t.datetime "birthdate", precision: nil
    t.bigint "group_id", default: 0, null: false
    t.datetime "group_id_updated_at", precision: nil
    t.jsonb "data", default: {}, null: false
    t.string "address1", default: "", null: false
    t.string "address2", default: "", null: false
    t.string "city", default: "", null: false
    t.string "state", default: "", null: false
    t.string "zipcode", default: "", null: false
    t.string "ext_ref_id", default: "", null: false
    t.bigint "stage_id", default: 0, null: false
    t.string "companyname", default: "", null: false
    t.boolean "sleep", default: false, null: false
    t.boolean "block", default: false, null: false
    t.bigint "lead_source_id"
    t.datetime "lead_source_id_updated_at"
    t.datetime "stage_id_updated_at"
    t.bigint "parent_id"
    t.bigint "campaign_group_id"
    t.index ["campaign_group_id"], name: "index_contacts_on_campaign_group_id"
    t.index ["client_id"], name: "index_contacts_on_client_id"
    t.index ["data"], name: "index_contacts_on_data", using: :gin
    t.index ["stage_id"], name: "index_contacts_on_stage_id"
    t.index ["user_id"], name: "index_contacts_on_users_id"
  end

  create_table "contacttags", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "tag_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["contact_id"], name: "index_contacttags_on_contact_id"
    t.index ["tag_id"], name: "index_contacttags_on_tag_id"
  end

  create_table "db_loaders", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "last_start_at"
    t.datetime "last_stop_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_db_loaders_on_key", unique: true
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "triggeraction_id"
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "user_id"
    t.string "process", default: ""
    t.bigint "contact_campaign_id", default: 0, null: false
    t.integer "group_process", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.string "group_uuid"
    t.index ["contact_campaign_id", "triggeraction_id"], name: "index_delayed_jobs_on_contact_campaign_id_and_triggeraction_id"
    t.index ["contact_id", "process"], name: "index_delayed_jobs_on_contact_id_and_process"
    t.index ["group_uuid", "user_id", "group_process"], name: "index_delayed_jobs_on_group_uuid_and_user_id_and_group_process"
    t.index ["priority", "run_at", "queue"], name: "index_delayed_jobs_priority_partial", where: "(failed_at IS NULL)"
    t.index ["process", "user_id"], name: "index_delayed_jobs_on_process_and_user_id"
    t.index ["triggeraction_id", "user_id", "run_at", "group_process", "failed_at", "locked_at"], name: "idx_on_triggeraction_id_user_id_run_at_group_proces_7b98c42455"
    t.index ["user_id", "triggeraction_id", "run_at", "process", "failed_at", "locked_at"], name: "idx_on_user_id_triggeraction_id_run_at_process_fail_6894360288"
  end

  create_table "email_templates", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name"
    t.string "subject"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "share_code", default: "", null: false
    t.text "html"
    t.text "css"
    t.string "category"
    t.integer "version", default: 2, null: false
    t.index ["client_id"], name: "index_email_templates_on_client_id"
    t.index ["name", "client_id"], name: "index_email_templates_on_name_and_client_id", unique: true
    t.index ["share_code"], name: "index_email_templates_on_share_code", unique: true
  end

  create_table "fcp_invoices", force: :cascade do |t|
    t.bigint "contact_id", default: 0
    t.text "invoice_id", default: "", null: false
    t.datetime "invoice_date", precision: nil
    t.decimal "total", default: "0.0", null: false
    t.text "ext_tech_id", default: "", null: false
    t.text "business_unit_id", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "job_type_id", default: "", null: false
    t.bigint "client_id", default: 0, null: false
    t.decimal "estimates_total", default: "0.0", null: false
    t.text "tech_lead_id", default: "", null: false
    t.text "recall_id", default: "", null: false
    t.integer "review"
    t.string "job_id", default: "", null: false
    t.index ["business_unit_id"], name: "index_fcp_invoices_on_business_unit_id"
    t.index ["client_id"], name: "index_fcp_invoices_on_client_id"
    t.index ["contact_id"], name: "index_service_titan_invoices_on_contacts_id"
    t.index ["ext_tech_id"], name: "index_fcp_invoices_on_ext_tech_id"
    t.index ["invoice_date"], name: "index_fcp_invoices_on_invoice_date"
    t.index ["invoice_id"], name: "index_fcp_invoices_on_invoice_id"
    t.index ["job_id"], name: "index_fcp_invoices_on_job_id"
    t.index ["job_type_id"], name: "index_fcp_invoices_on_job_type_id"
    t.index ["review"], name: "index_fcp_invoices_on_review"
    t.index ["total"], name: "index_fcp_invoices_on_total"
  end

  create_table "folders", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["client_id"], name: "index_folders_on_client_id"
    t.index ["name"], name: "index_folders_on_name"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_groups_on_client_id"
    t.index ["name"], name: "index_groups_on_name"
  end

  create_table "integrations", force: :cascade do |t|
    t.string "company_name"
    t.boolean "show_company_name", default: true
    t.string "contact"
    t.string "short_description"
    t.text "description"
    t.string "phone_number"
    t.boolean "preferred", default: false
    t.integer "sort_order", default: 0
    t.string "website_url"
    t.string "image_url"
    t.string "youtube_url"
    t.string "controller"
    t.string "integration"
    t.string "link_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "message_attachments", force: :cascade do |t|
    t.bigint "message_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "contact_attachment_id"
    t.index ["message_id"], name: "index_message_attachments_on_message_id"
  end

  create_table "message_emails", force: :cascade do |t|
    t.bigint "message_id"
    t.string "text_body", default: "", null: false
    t.string "html_body", default: "", null: false
    t.string "headers", default: "", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_emails_on_message_id"
  end

  create_table "message_folder_assignments", force: :cascade do |t|
    t.bigint "message_id"
    t.bigint "folder_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_message_folder_assignments_on_folder_id"
    t.index ["message_id"], name: "index_message_folder_assignments_on_message_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "message"
    t.bigint "contact_id"
    t.datetime "updated_at", precision: nil, null: false
    t.string "message_sid"
    t.string "account_sid"
    t.string "from_phone", default: "", null: false
    t.string "to_phone", default: "", null: false
    t.datetime "read_at", precision: nil
    t.string "status"
    t.string "error_code"
    t.string "error_message"
    t.string "from_state"
    t.string "from_zip", limit: 10
    t.string "from_city"
    t.bigint "triggeraction_id"
    t.bigint "voice_mail_recording_id", default: 0
    t.decimal "cost", default: "0.0", null: false
    t.integer "num_segments", default: 0, null: false
    t.string "msg_type", default: "", null: false
    t.boolean "automated", default: false, null: false
    t.bigint "user_id"
    t.bigint "voice_recording_id"
    t.bigint "read_at_user_id"
    t.bigint "aiagent_session_id"
    t.datetime "created_at", precision: nil, null: false
    t.index ["aiagent_session_id"], name: "index_messages_on_aiagent_session_id"
    t.index ["contact_id", "read_at", "automated"], name: "index_messages_on_contact_id_and_read_at_and_automated"
    t.index ["created_at", "read_at", "automated"], name: "index_messages_on_created_at_and_read_at_and_automated"
    t.index ["message"], name: "trgm_idx_twmessages_message", opclass: :gin_trgm_ops, using: :gin
    t.index ["message_sid"], name: "index_messages_on_message_sid"
    t.index ["read_at", "automated", "contact_id"], name: "index_messages_on_read_at_and_automated_and_contact_id"
    t.index ["status", "created_at", "voice_recording_id"], name: "index_messages_on_status_and_created_at_and_voice_recording_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "scopes", default: "", null: false
    t.string "code_challenge"
    t.string "code_challenge_method"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "org_positions", force: :cascade do |t|
    t.bigint "client_id"
    t.string "title", default: "", null: false
    t.bigint "level", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "client_custom_field_id", default: 0, null: false
    t.index ["client_custom_field_id"], name: "index_org_positions_on_client_custom_field_id"
    t.index ["client_id"], name: "index_org_positions_on_client_id"
    t.index ["level"], name: "index_org_positions_on_level"
  end

  create_table "org_users", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "user_id", default: 0, null: false
    t.bigint "org_group", default: 0, null: false
    t.bigint "org_position_id", default: 0, null: false
    t.string "firstname", default: "", null: false
    t.string "lastname", default: "", null: false
    t.string "phone", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "email", default: "", null: false
    t.index ["client_id"], name: "index_org_users_on_client_id"
    t.index ["org_position_id"], name: "index_org_users_on_org_position_id"
    t.index ["user_id"], name: "index_org_users_on_user_id"
  end

  create_table "package_campaigns", force: :cascade do |t|
    t.bigint "package_id"
    t.bigint "campaign_id"
    t.bigint "campaign_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["campaign_group_id"], name: "index_package_campaigns_on_campaign_group_id"
    t.index ["campaign_id"], name: "index_package_campaigns_on_campaign_id"
    t.index ["package_id"], name: "index_package_campaigns_on_package_id"
  end

  create_table "package_pages", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "page_key", default: "", null: false
    t.integer "package_01_id", default: 0, null: false
    t.integer "package_02_id", default: 0, null: false
    t.integer "package_03_id", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sys_default", default: 0, null: false
    t.integer "primary_package", default: 0, null: false
    t.integer "package_04_id", default: 0, null: false
    t.string "tenant", default: "", null: false
    t.boolean "onetime", default: false, null: false
    t.date "expired_on"
    t.index ["name"], name: "index_package_pages_on_name"
    t.index ["page_key"], name: "index_package_pages_on_page_key"
    t.index ["tenant"], name: "index_package_pages_on_tenant"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "package_key", default: "", null: false
    t.jsonb "package_data", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "tenant", default: "", null: false
    t.string "phone_vendor", default: "bandwidth", null: false
    t.bigint "affiliate_id"
    t.boolean "onetime", default: false, null: false
    t.date "expired_on"
    t.index ["affiliate_id"], name: "index_packages_on_affiliate_id"
    t.index ["name"], name: "index_packages_on_name"
    t.index ["package_data"], name: "index_packages_on_package_data", using: :gin
    t.index ["package_key"], name: "index_packages_on_package_key"
    t.index ["tenant"], name: "index_packages_on_tenant"
  end

  create_table "payment_transactions", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "contact_jobs_id"
    t.string "target", null: false
    t.string "payment_type", null: false
    t.decimal "amount_total", default: "0.0", null: false
    t.decimal "amount_requested", default: "0.0", null: false
    t.decimal "amount_fees", default: "0.0", null: false
    t.datetime "transacted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_payment_transactions_on_client_id"
    t.index ["contact_jobs_id"], name: "index_payment_transactions_on_contact_jobs_id"
    t.index ["target"], name: "index_payment_transactions_on_target"
    t.index ["transacted_at"], name: "index_payment_transactions_on_transacted_at"
  end

  create_table "postcards", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "contact_id"
    t.bigint "tag_id"
    t.string "target", default: "", null: false
    t.string "card_id", default: "", null: false
    t.string "card_name", default: "", null: false
    t.string "result", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_postcards_on_card_id"
    t.index ["client_id"], name: "index_postcards_on_client_id"
    t.index ["contact_id"], name: "index_postcards_on_contact_id"
    t.index ["tag_id"], name: "index_postcards_on_tag_id"
  end

  create_table "quick_responses", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.text "message"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_quick_responses_on_client_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "contact_id"
    t.string "name", default: "", null: false
    t.string "review_id", default: "", null: false
    t.integer "star_rating", default: 5, null: false
    t.string "comment", default: "", null: false
    t.string "reply", default: "", null: false
    t.datetime "replied_at"
    t.string "target", default: "", null: false
    t.datetime "target_created_at"
    t.datetime "target_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account", default: "", null: false
    t.string "location", default: "", null: false
    t.datetime "read_at"
    t.index ["account"], name: "index_reviews_on_account"
    t.index ["client_id"], name: "index_reviews_on_client_id"
    t.index ["contact_id"], name: "index_reviews_on_contact_id"
    t.index ["location"], name: "index_reviews_on_location"
    t.index ["review_id"], name: "index_reviews_on_review_id"
  end

  create_table "short_codes", force: :cascade do |t|
    t.bigint "client_id"
    t.string "code", null: false
    t.text "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_short_codes_on_client_id"
    t.index ["code"], name: "index_short_codes_on_code", unique: true
  end

  create_table "sign_in_debugs", force: :cascade do |t|
    t.bigint "user_id"
    t.boolean "user_signed_in?", default: false, null: false
    t.string "email"
    t.string "commit"
    t.string "remote_ip"
    t.text "user_agent"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data"], name: "index_sign_in_debugs_on_data", using: :gin
    t.index ["email", "user_signed_in?"], name: "index_sign_in_debugs_on_email_and_user_signed_in?"
    t.index ["email"], name: "index_sign_in_debugs_on_email"
    t.index ["remote_ip"], name: "index_sign_in_debugs_on_remote_ip"
    t.index ["user_id"], name: "index_sign_in_debugs_on_user_id"
  end

  create_table "stage_parents", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "share_code", default: "", null: false
    t.index ["client_id"], name: "index_stage_parents_on_client_id"
    t.index ["name"], name: "index_stage_parents_on_name"
  end

  create_table "stages", force: :cascade do |t|
    t.bigint "stage_parent_id"
    t.bigint "campaign_id", default: 0, null: false
    t.string "name", default: "", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data", default: {}, null: false
    t.index ["campaign_id"], name: "index_stages_on_campaign_id"
    t.index ["name"], name: "index_stages_on_name"
    t.index ["stage_parent_id"], name: "index_stages_on_stage_parent_id"
  end

  create_table "survey_results", force: :cascade do |t|
    t.bigint "survey_id"
    t.bigint "contact_id"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_survey_results_on_contact_id"
    t.index ["survey_id"], name: "index_survey_results_on_survey_id"
  end

  create_table "survey_screens", force: :cascade do |t|
    t.bigint "survey_id"
    t.string "name", default: "", null: false
    t.string "screen_type", default: "", null: false
    t.string "screen_key", default: "", null: false
    t.integer "hits", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_survey_screens_on_name"
    t.index ["screen_key"], name: "index_survey_screens_on_screen_key"
    t.index ["survey_id"], name: "index_survey_screens_on_survey_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: "", null: false
    t.string "survey_key", default: "", null: false
    t.string "share_code", default: "", null: false
    t.integer "hits", default: 0, null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_surveys_on_client_id"
    t.index ["name"], name: "index_surveys_on_name"
    t.index ["share_code"], name: "index_surveys_on_share_code"
    t.index ["survey_key"], name: "index_surveys_on_survey_key"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.bigint "client_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "campaign_id", default: 0, null: false
    t.bigint "group_id", default: 0, null: false
    t.bigint "tag_id", default: 0, null: false
    t.string "color", default: "", null: false
    t.bigint "stage_id", default: 0, null: false
    t.bigint "stop_campaign_ids", default: [], array: true
    t.index ["campaign_id"], name: "index_tags_on_campaign_id"
    t.index ["client_id"], name: "index_tags_on_client_id"
    t.index ["group_id"], name: "index_tags_on_group_id"
    t.index ["name"], name: "index_tags_on_name"
    t.index ["stage_id"], name: "index_tags_on_stage_id"
    t.index ["tag_id"], name: "index_tags_on_tag_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "user_id"
    t.bigint "contact_id"
    t.string "name", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "due_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deadline_at", precision: nil
    t.datetime "notified_at", precision: nil
    t.bigint "campaign_id", default: 0, null: false
    t.string "from_phone", default: "", null: false
    t.integer "cancel_after", default: 0, null: false
    t.index ["campaign_id"], name: "index_tasks_on_campaign_id"
    t.index ["client_id"], name: "index_tasks_on_client_id"
    t.index ["contact_id"], name: "index_tasks_on_contact_id"
    t.index ["name"], name: "index_tasks_on_name"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "tenant_costs", force: :cascade do |t|
    t.string "tenant", default: "", null: false
    t.integer "month", default: 0, null: false
    t.integer "year", default: 0, null: false
    t.string "cost_key", default: "", null: false
    t.decimal "cost_value", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant", "month", "year", "cost_key"], name: "index_tenant_costs_on_tenant_and_month_and_year_and_cost_key"
  end

  create_table "trackable_links", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "tag_id"
    t.bigint "campaign_id"
    t.string "name"
    t.string "original_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "group_id", default: 0, null: false
    t.bigint "stage_id", default: 0, null: false
    t.bigint "stop_campaign_ids", default: [], array: true
    t.index ["campaign_id"], name: "index_trackable_links_on_campaign_id"
    t.index ["client_id"], name: "index_trackable_links_on_client_id"
    t.index ["group_id"], name: "index_trackable_links_on_group_id"
    t.index ["stage_id"], name: "index_trackable_links_on_stage_id"
    t.index ["tag_id"], name: "index_trackable_links_on_tag_id"
  end

  create_table "trackable_links_hits", force: :cascade do |t|
    t.bigint "trackable_short_link_id"
    t.string "referer"
    t.string "remote_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["trackable_short_link_id"], name: "index_trackable_links_hits_on_trackable_short_link_id"
  end

  create_table "trackable_short_links", force: :cascade do |t|
    t.bigint "trackable_link_id"
    t.string "short_code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "contact_id"
    t.index ["contact_id"], name: "index_trackable_short_links_on_contact_id"
    t.index ["trackable_link_id"], name: "index_trackable_short_links_on_trackable_link_id"
  end

  create_table "training_pages", force: :cascade do |t|
    t.bigint "training_id", default: 0, null: false
    t.string "menu_label", default: "", null: false
    t.string "title", default: "", null: false
    t.boolean "parent", default: false, null: false
    t.integer "position", default: 0, null: false
    t.text "header", default: "", null: false
    t.text "footer", default: "", null: false
    t.string "video_link", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["position"], name: "index_training_pages_on_position"
    t.index ["training_id"], name: "index_training_pages_on_training_id"
  end

  create_table "trainings", force: :cascade do |t|
    t.string "menu_label", default: "", null: false
    t.string "title", default: "", null: false
    t.string "description", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "triggeractions", force: :cascade do |t|
    t.bigint "trigger_id"
    t.integer "action_type", limit: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sequence", default: 0
    t.jsonb "data", default: {}, null: false
    t.index ["data"], name: "index_triggeractions_on_data", using: :gin
    t.index ["trigger_id"], name: "index_triggeractions_on_trigger_id"
  end

  create_table "triggers", force: :cascade do |t|
    t.bigint "campaign_id"
    t.integer "trigger_type", limit: 2
    t.string "keyword"
    t.text "data"
    t.integer "step_numb", limit: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", default: "", null: false
    t.index ["campaign_id"], name: "index_triggers_on_campaign_id"
    t.index ["keyword"], name: "index_triggers_on_keyword"
    t.index ["step_numb"], name: "index_triggers_on_step_numb"
  end

  create_table "twnumbers", force: :cascade do |t|
    t.string "phonenumber", default: "", null: false
    t.bigint "client_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", default: ""
    t.string "vendor_id", default: "", null: false
    t.jsonb "data", default: {}, null: false
    t.string "phone_vendor", default: "bandwidth", null: false
    t.bigint "vm_greeting_recording_id"
    t.bigint "announcement_recording_id"
    t.bigint "dlc10_campaign_id"
    t.index ["announcement_recording_id"], name: "index_twnumbers_on_announcement_recording_id"
    t.index ["client_id"], name: "index_twnumbers_on_client_id"
    t.index ["dlc10_campaign_id"], name: "index_twnumbers_on_dlc10_campaign_id"
    t.index ["phonenumber"], name: "index_twnumbers_on_phonenumber", unique: true
    t.index ["vm_greeting_recording_id"], name: "index_twnumbers_on_vm_greeting_recording_id"
  end

  create_table "twnumberusers", force: :cascade do |t|
    t.integer "user_id"
    t.integer "twnumber_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "def_user", default: false, null: false
    t.index ["twnumber_id"], name: "index_twnumberusers_on_twnumber_id"
    t.index ["user_id"], name: "index_twnumberusers_on_user_id"
  end

  create_table "user_api_integrations", force: :cascade do |t|
    t.bigint "user_id"
    t.string "target", default: "", null: false
    t.string "name", default: "", null: false
    t.string "api_key", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "data", default: {}, null: false
    t.index ["data"], name: "index_user_api_integrations_on_data", using: :gin
    t.index ["name"], name: "index_user_api_integrations_on_name"
    t.index ["target"], name: "index_user_api_integrations_on_target"
    t.index ["user_id"], name: "index_user_api_integrations_on_user_id"
  end

  create_table "user_attachments", force: :cascade do |t|
    t.bigint "user_id"
    t.string "image"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_user_attachments_on_user_id"
  end

  create_table "user_chats", force: :cascade do |t|
    t.bigint "from_user_id"
    t.bigint "to_user_id"
    t.bigint "contact_id", default: 0
    t.text "content", default: "", null: false
    t.datetime "read_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "automated", default: false, null: false
    t.index ["contact_id"], name: "index_user_chats_on_contacts_id"
    t.index ["from_user_id"], name: "index_user_chats_on_from_user_id"
    t.index ["to_user_id"], name: "index_user_chats_on_to_user_id"
  end

  create_table "user_contact_forms", force: :cascade do |t|
    t.bigint "user_id"
    t.string "title", default: "", null: false
    t.text "header_notes", default: "", null: false
    t.text "footer_notes", default: "", null: false
    t.string "redirect_url", default: "", null: false
    t.string "page_key", default: "", null: false
    t.integer "campaign_id", default: 0, null: false
    t.integer "tag_id", default: 0, null: false
    t.text "form_fields", default: ""
    t.jsonb "formatting", default: {}, null: false
    t.string "form_name", default: "", null: false
    t.string "share_code", default: "", null: false
    t.bigint "group_id", default: 0, null: false
    t.datetime "created_at", precision: nil, default: "2019-05-29 16:11:39", null: false
    t.datetime "updated_at", precision: nil, default: "2019-05-29 16:11:39", null: false
    t.boolean "marketplace", default: false, null: false
    t.boolean "marketplace_ok", default: false, null: false
    t.decimal "price", default: "0.0", null: false
    t.string "page_domain", default: "", null: false
    t.string "page_name", default: "", null: false
    t.bigint "stage_id", default: 0, null: false
    t.bigint "stop_campaign_ids", default: [], array: true
    t.index ["campaign_id"], name: "index_user_contact_forms_on_campaign_id"
    t.index ["formatting"], name: "index_user_contact_forms_on_formatting", using: :gin
    t.index ["group_id"], name: "index_user_contact_forms_on_group_id"
    t.index ["page_domain"], name: "index_user_contact_forms_on_page_domain"
    t.index ["page_key"], name: "index_user_contact_forms_on_page_key"
    t.index ["page_name"], name: "index_user_contact_forms_on_page_name"
    t.index ["share_code"], name: "index_user_contact_forms_on_share_code"
    t.index ["stage_id"], name: "index_user_contact_forms_on_stage_id"
    t.index ["tag_id"], name: "index_user_contact_forms_on_tag_id"
    t.index ["user_id"], name: "index_user_contact_forms_on_user_id"
  end

  create_table "user_pushes", force: :cascade do |t|
    t.bigint "user_id"
    t.string "player_id", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "target", default: "", null: false
    t.jsonb "data", default: {}, null: false
    t.index ["player_id"], name: "index_user_pushes_on_player_id"
    t.index ["user_id"], name: "index_user_pushes_on_user_id"
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id"
    t.string "controller_action", default: "", null: false
    t.string "name", default: "", null: false
    t.text "data", default: "\n"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "current", default: 0, null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "firstname", default: "", null: false
    t.string "lastname", default: "", null: false
    t.string "phone", default: "", null: false
    t.string "email", default: "", null: false
    t.bigint "client_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.integer "access_level", default: 0
    t.string "provider"
    t.string "uid"
    t.string "user_avatar"
    t.jsonb "data", default: {}, null: false
    t.datetime "suspended_at", precision: nil
    t.string "ext_ref_id", default: "", null: false
    t.jsonb "permissions", default: {}, null: false
    t.string "otp_secret"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "locked_at"
    t.integer "failed_attempts"
    t.string "unlock_token"
    t.string "otp_secret_at"
    t.index "lower((email)::text) text_pattern_ops", name: "users_email_lower", unique: true
    t.index ["client_id"], name: "index_users_on_client_id"
    t.index ["data"], name: "index_users_on_data", using: :gin
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["ext_ref_id"], name: "index_users_on_ext_ref_id"
    t.index ["firstname"], name: "index_users_on_firstname"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["lastname"], name: "index_users_on_lastname"
    t.index ["phone"], name: "index_users_on_phone"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "start_date", precision: nil
    t.string "header", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "description", default: "", null: false
    t.jsonb "data", default: {}, null: false
    t.index ["data"], name: "index_versions_on_data", using: :gin
    t.index ["start_date"], name: "index_versions_on_start_date"
  end

  create_table "voice_mail_recordings", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name", default: ""
    t.string "sid", default: ""
    t.string "url", default: ""
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_voice_mail_recordings_on_client_id"
  end

  create_table "voice_recordings", force: :cascade do |t|
    t.bigint "client_id"
    t.string "recording_name", default: "", null: false
    t.string "sid", default: "", null: false
    t.string "url", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_voice_recordings_on_client_id"
    t.index ["recording_name"], name: "index_voice_recordings_on_recording_name"
  end

  create_table "webhook_maps", force: :cascade do |t|
    t.bigint "webhook_id"
    t.string "external_key"
    t.string "internal_key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "response"
    t.index ["webhook_id"], name: "index_webhook_maps_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "client_id"
    t.string "name"
    t.string "token"
    t.string "testing"
    t.text "sample_data"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "campaign_id", default: 0
    t.bigint "tag_id"
    t.bigint "group_id", default: 0, null: false
    t.string "data_type", default: "", null: false
    t.bigint "stage_id", default: 0, null: false
    t.bigint "stop_campaign_ids", default: [], array: true
    t.index ["campaign_id"], name: "index_webhooks_on_campaign_id"
    t.index ["client_id"], name: "index_webhooks_on_client_id"
    t.index ["group_id"], name: "index_webhooks_on_group_id"
    t.index ["stage_id"], name: "index_webhooks_on_stage_id"
    t.index ["tag_id"], name: "index_webhooks_on_tag_id"
    t.index ["token"], name: "index_webhooks_on_token"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "aiagent_messages", "aiagent_sessions"
  add_foreign_key "aiagent_messages", "messages"
  add_foreign_key "aiagent_sessions", "aiagents"
  add_foreign_key "aiagent_sessions", "contacts"
  add_foreign_key "aiagents", "campaigns"
  add_foreign_key "aiagents", "campaigns", column: "help_campaign_id"
  add_foreign_key "aiagents", "clients"
  add_foreign_key "aiagents", "groups"
  add_foreign_key "aiagents", "groups", column: "help_group_id"
  add_foreign_key "aiagents", "stages"
  add_foreign_key "aiagents", "stages", column: "help_stage_id"
  add_foreign_key "aiagents", "tags"
  add_foreign_key "aiagents", "tags", column: "help_tag_id"
  add_foreign_key "campaign_share_codes", "campaign_groups", on_delete: :cascade
  add_foreign_key "campaign_share_codes", "campaigns", on_delete: :cascade
  add_foreign_key "campaigns", "clients", on_delete: :cascade
  add_foreign_key "client_api_calls", "clients"
  add_foreign_key "client_api_integrations", "clients", on_delete: :cascade
  add_foreign_key "client_attachments", "clients", on_delete: :cascade
  add_foreign_key "client_custom_fields", "clients", on_delete: :cascade
  add_foreign_key "client_dlc10_brands", "clients"
  add_foreign_key "client_dlc10_campaigns", "client_dlc10_brands", column: "dlc10_brand_id"
  add_foreign_key "client_holidays", "clients"
  add_foreign_key "client_kpis", "clients"
  add_foreign_key "client_notes", "clients"
  add_foreign_key "client_notes", "users"
  add_foreign_key "client_transactions", "clients", on_delete: :cascade
  add_foreign_key "client_widgets", "clients", on_delete: :cascade
  add_foreign_key "clients", "affiliates"
  add_foreign_key "clients", "package_pages"
  add_foreign_key "clients", "packages"
  add_foreign_key "clients", "users", column: "def_user_id", on_delete: :cascade
  add_foreign_key "clients_lead_sources", "clients"
  add_foreign_key "comments", "articles"
  add_foreign_key "contact_api_integrations", "contacts", on_delete: :cascade
  add_foreign_key "contact_campaign_triggeractions", "contact_campaigns", on_delete: :cascade
  add_foreign_key "contact_campaign_triggeractions", "triggeractions", on_delete: :cascade
  add_foreign_key "contact_campaigns", "campaigns", on_delete: :cascade
  add_foreign_key "contact_campaigns", "contacts", on_delete: :cascade
  add_foreign_key "contact_custom_fields", "client_custom_fields", on_delete: :cascade
  add_foreign_key "contact_custom_fields", "contacts", on_delete: :cascade
  add_foreign_key "contact_estimate_options", "contact_estimates", column: "estimate_id"
  add_foreign_key "contact_estimates", "contact_jobs", column: "job_id"
  add_foreign_key "contact_estimates", "contacts"
  add_foreign_key "contact_ext_references", "contacts"
  add_foreign_key "contact_fb_pages", "contacts"
  add_foreign_key "contact_ggl_conversations", "contacts"
  add_foreign_key "contact_invoices", "contact_jobs", column: "job_id"
  add_foreign_key "contact_invoices", "contacts"
  add_foreign_key "contact_jobs", "contacts"
  add_foreign_key "contact_phones", "contacts", on_delete: :cascade
  add_foreign_key "contact_raw_posts", "contacts"
  add_foreign_key "contact_requests", "contacts"
  add_foreign_key "contact_subscriptions", "contacts"
  add_foreign_key "contact_visits", "contact_jobs", column: "job_id"
  add_foreign_key "contact_visits", "contacts"
  add_foreign_key "contacts", "campaign_groups"
  add_foreign_key "contacts", "clients", on_delete: :cascade
  add_foreign_key "contacts", "clients_lead_sources", column: "lead_source_id", name: "asdf"
  add_foreign_key "contacts", "contacts", column: "parent_id"
  add_foreign_key "email_templates", "clients"
  add_foreign_key "folders", "clients"
  add_foreign_key "message_attachments", "messages", on_delete: :cascade
  add_foreign_key "message_emails", "messages"
  add_foreign_key "message_folder_assignments", "folders"
  add_foreign_key "message_folder_assignments", "messages"
  add_foreign_key "messages", "aiagent_sessions"
  add_foreign_key "messages", "contacts", on_delete: :cascade
  add_foreign_key "messages", "triggeractions", validate: false
  add_foreign_key "messages", "users"
  add_foreign_key "messages", "users", column: "read_at_user_id"
  add_foreign_key "messages", "voice_recordings"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "org_positions", "clients", on_delete: :cascade
  add_foreign_key "org_users", "clients", on_delete: :cascade
  add_foreign_key "package_campaigns", "packages", on_delete: :cascade
  add_foreign_key "packages", "affiliates"
  add_foreign_key "payment_transactions", "clients", on_delete: :nullify
  add_foreign_key "payment_transactions", "contact_jobs", column: "contact_jobs_id", on_delete: :nullify
  add_foreign_key "postcards", "clients"
  add_foreign_key "postcards", "contacts"
  add_foreign_key "postcards", "tags"
  add_foreign_key "quick_responses", "clients"
  add_foreign_key "reviews", "clients"
  add_foreign_key "reviews", "contacts"
  add_foreign_key "sign_in_debugs", "users"
  add_foreign_key "stage_parents", "clients"
  add_foreign_key "stages", "stage_parents"
  add_foreign_key "survey_results", "contacts"
  add_foreign_key "survey_results", "surveys"
  add_foreign_key "survey_screens", "surveys"
  add_foreign_key "surveys", "clients"
  add_foreign_key "tasks", "clients", on_delete: :cascade
  add_foreign_key "trackable_links", "clients", on_delete: :cascade
  add_foreign_key "trackable_links_hits", "trackable_short_links", on_delete: :cascade
  add_foreign_key "trackable_short_links", "trackable_links", on_delete: :cascade
  add_foreign_key "triggeractions", "triggers", on_delete: :cascade
  add_foreign_key "triggers", "campaigns", on_delete: :cascade
  add_foreign_key "twnumbers", "clients", on_delete: :cascade
  add_foreign_key "twnumbers", "voice_recordings", column: "announcement_recording_id"
  add_foreign_key "twnumbers", "voice_recordings", column: "vm_greeting_recording_id"
  add_foreign_key "user_api_integrations", "users", on_delete: :cascade
  add_foreign_key "user_attachments", "users", on_delete: :cascade
  add_foreign_key "user_chats", "users", column: "from_user_id", on_delete: :cascade
  add_foreign_key "user_chats", "users", column: "to_user_id", on_delete: :cascade
  add_foreign_key "user_contact_forms", "users", on_delete: :cascade
  add_foreign_key "user_pushes", "users", on_delete: :cascade
  add_foreign_key "user_settings", "users", on_delete: :cascade
  add_foreign_key "users", "clients", on_delete: :cascade
  add_foreign_key "voice_mail_recordings", "clients", on_delete: :cascade
  add_foreign_key "voice_recordings", "clients"
  add_foreign_key "webhook_maps", "webhooks", on_delete: :cascade
  add_foreign_key "webhooks", "clients", on_delete: :cascade
end
