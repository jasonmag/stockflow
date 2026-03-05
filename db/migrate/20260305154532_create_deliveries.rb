class CreateDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :deliveries do |t|
      t.references :business, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.date :delivered_on, null: false
      t.string :delivery_number, null: false
      t.integer :status, null: false, default: 0
      t.references :from_location, null: true, foreign_key: { to_table: :locations }
      t.text :notes
      t.boolean :show_prices, null: false, default: false

      t.timestamps
    end

    add_index :deliveries, [ :business_id, :delivery_number ], unique: true
  end
end
