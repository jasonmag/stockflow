class CreateStockCountSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_count_sessions do |t|
      t.references :business, null: false, foreign_key: true
      t.references :location, foreign_key: true
      t.string :reference_number, null: false
      t.date :count_date, null: false
      t.time :count_time, null: false
      t.integer :count_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :performed_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.timestamps
    end

    add_index :stock_count_sessions, [ :business_id, :reference_number ], unique: true

    create_table :stock_count_items do |t|
      t.references :stock_count_session, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :expected_quantity, precision: 12, scale: 2, null: false
      t.decimal :actual_quantity, precision: 12, scale: 2
      t.decimal :variance, precision: 12, scale: 2, null: false, default: 0
      t.string :variance_reason
      t.text :notes
      t.timestamps
    end

    add_index :stock_count_items, [ :stock_count_session_id, :product_id ], unique: true, name: "index_stock_count_items_on_session_and_product"

    create_table :inventory_adjustments do |t|
      t.references :business, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :stock_count_session, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.decimal :adjustment_quantity, precision: 12, scale: 2, null: false
      t.string :reason, null: false
      t.text :notes
      t.timestamps
    end

    create_table :stock_count_events do |t|
      t.references :stock_count_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.text :details
      t.timestamps
    end

    add_index :stock_count_events, [ :stock_count_session_id, :created_at ]
  end
end
