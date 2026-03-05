class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.references :business, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.date :purchased_on
      t.references :receiving_location, null: false, foreign_key: { to_table: :locations }
      t.integer :funding_source, null: false, default: 0
      t.text :notes
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
