class CreatePurchaseItems < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, null: false, precision: 12, scale: 2
      t.integer :unit_cost_cents, null: false

      t.timestamps
    end
  end
end
