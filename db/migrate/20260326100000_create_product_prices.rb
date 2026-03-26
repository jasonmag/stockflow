class CreateProductPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.date :effective_on, null: false
      t.integer :price_cents, null: false

      t.timestamps
    end

    add_index :product_prices, [ :product_id, :effective_on ], unique: true
  end
end
