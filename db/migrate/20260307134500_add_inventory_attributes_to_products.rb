class AddInventoryAttributesToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :inventory_type, :integer, null: false, default: 0
    add_column :products, :brand, :string
    add_column :products, :barcode, :string
    add_column :products, :description, :text
    add_column :products, :base_cost_cents, :integer
    add_index :products, [ :business_id, :barcode ], unique: true
  end
end
