class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_movements do |t|
      t.references :business, null: false, foreign_key: true
      t.integer :movement_type, null: false
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, null: false, precision: 12, scale: 2
      t.integer :unit_cost_cents
      t.references :from_location, null: true, foreign_key: { to_table: :locations }
      t.references :to_location, null: true, foreign_key: { to_table: :locations }
      t.date :occurred_on, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.text :notes

      t.timestamps
    end
  end
end
