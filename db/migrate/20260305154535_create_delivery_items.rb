class CreateDeliveryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_items do |t|
      t.references :delivery, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, null: false, precision: 12, scale: 2
      t.integer :unit_price_cents

      t.timestamps
    end
  end
end
