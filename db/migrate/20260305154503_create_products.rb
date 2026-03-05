class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku
      t.string :unit, null: false
      t.integer :reorder_level
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
