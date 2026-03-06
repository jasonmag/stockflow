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

ActiveRecord::Schema[8.0].define(version: 2026_03_06_184917) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "businesses", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_email"
    t.string "contact_phone"
    t.text "address"
    t.integer "reminder_lead_days", default: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "name"], name: "index_categories_on_business_id_and_name", unique: true
    t.index ["business_id"], name: "index_categories_on_business_id"
  end

  create_table "collections", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "receivable_id"
    t.date "collected_on", null: false
    t.integer "amount_cents", null: false
    t.integer "method", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_collections_on_business_id"
    t.index ["receivable_id"], name: "index_collections_on_receivable_id"
  end

  create_table "customers", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.string "contact_name"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_customers_on_business_id"
  end

  create_table "deliveries", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "customer_id", null: false
    t.date "delivered_on", null: false
    t.string "delivery_number", null: false
    t.integer "status", default: 0, null: false
    t.integer "from_location_id"
    t.text "notes"
    t.boolean "show_prices", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "delivery_number"], name: "index_deliveries_on_business_id_and_delivery_number", unique: true
    t.index ["business_id"], name: "index_deliveries_on_business_id"
    t.index ["customer_id"], name: "index_deliveries_on_customer_id"
    t.index ["from_location_id"], name: "index_deliveries_on_from_location_id"
  end

  create_table "delivery_email_logs", force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.integer "sent_by_user_id", null: false
    t.text "recipients"
    t.string "subject"
    t.text "message"
    t.datetime "sent_at"
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_delivery_email_logs_on_delivery_id"
    t.index ["sent_by_user_id"], name: "index_delivery_email_logs_on_sent_by_user_id"
  end

  create_table "delivery_items", force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.integer "product_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, null: false
    t.integer "unit_price_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_delivery_items_on_delivery_id"
    t.index ["product_id"], name: "index_delivery_items_on_product_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.integer "business_id", null: false
    t.date "occurred_on", null: false
    t.string "payee", null: false
    t.integer "category_id", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PHP", null: false
    t.integer "funding_source", default: 0, null: false
    t.integer "payment_method", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_expenses_on_business_id"
    t.index ["category_id"], name: "index_expenses_on_category_id"
  end

  create_table "locations", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.integer "location_type", default: 5, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_locations_on_business_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "business_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_memberships_on_business_id"
    t.index ["user_id", "business_id"], name: "index_memberships_on_user_id_and_business_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "user_id", null: false
    t.string "notifiable_type", null: false
    t.integer "notifiable_id", null: false
    t.string "message", null: false
    t.date "due_on", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_notifications_on_business_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payables", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "payable_type", default: 0, null: false
    t.string "payee", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PHP", null: false
    t.date "due_on", null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.string "recurring_rule"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_payables_on_business_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "payable_id"
    t.integer "expense_id"
    t.date "paid_on", null: false
    t.integer "amount_cents", null: false
    t.integer "method", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_payments_on_business_id"
    t.index ["expense_id"], name: "index_payments_on_expense_id"
    t.index ["payable_id"], name: "index_payments_on_payable_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.string "sku"
    t.string "unit", null: false
    t.integer "reorder_level"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_products_on_business_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.integer "purchase_id", null: false
    t.integer "product_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, null: false
    t.integer "unit_cost_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "supplier_id", null: false
    t.date "purchased_on"
    t.integer "receiving_location_id", null: false
    t.integer "funding_source", default: 0, null: false
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_purchases_on_business_id"
    t.index ["receiving_location_id"], name: "index_purchases_on_receiving_location_id"
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
  end

  create_table "receivables", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "customer_id", null: false
    t.string "reference"
    t.date "delivered_on"
    t.date "due_on", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "PHP", null: false
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_receivables_on_business_id"
    t.index ["customer_id"], name: "index_receivables_on_customer_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.integer "business_id", null: false
    t.integer "movement_type", null: false
    t.integer "product_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, null: false
    t.integer "unit_cost_cents"
    t.integer "from_location_id"
    t.integer "to_location_id"
    t.date "occurred_on", null: false
    t.string "reference_type"
    t.bigint "reference_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_stock_movements_on_business_id"
    t.index ["from_location_id"], name: "index_stock_movements_on_from_location_id"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["to_location_id"], name: "index_stock_movements_on_to_location_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.integer "business_id", null: false
    t.string "name", null: false
    t.string "contact_name"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_suppliers_on_business_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system_admin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["system_admin"], name: "index_users_on_system_admin"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories", "businesses"
  add_foreign_key "collections", "businesses"
  add_foreign_key "collections", "receivables"
  add_foreign_key "customers", "businesses"
  add_foreign_key "deliveries", "businesses"
  add_foreign_key "deliveries", "customers"
  add_foreign_key "deliveries", "locations", column: "from_location_id"
  add_foreign_key "delivery_email_logs", "deliveries"
  add_foreign_key "delivery_email_logs", "users", column: "sent_by_user_id"
  add_foreign_key "delivery_items", "deliveries"
  add_foreign_key "delivery_items", "products"
  add_foreign_key "expenses", "businesses"
  add_foreign_key "expenses", "categories"
  add_foreign_key "locations", "businesses"
  add_foreign_key "memberships", "businesses"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "businesses"
  add_foreign_key "notifications", "users"
  add_foreign_key "payables", "businesses"
  add_foreign_key "payments", "businesses"
  add_foreign_key "payments", "expenses"
  add_foreign_key "payments", "payables"
  add_foreign_key "products", "businesses"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "businesses"
  add_foreign_key "purchases", "locations", column: "receiving_location_id"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "receivables", "businesses"
  add_foreign_key "receivables", "customers"
  add_foreign_key "sessions", "users"
  add_foreign_key "stock_movements", "businesses"
  add_foreign_key "stock_movements", "locations", column: "from_location_id"
  add_foreign_key "stock_movements", "locations", column: "to_location_id"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "suppliers", "businesses"
end
