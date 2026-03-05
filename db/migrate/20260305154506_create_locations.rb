class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :location_type, null: false, default: 5

      t.timestamps
    end
  end
end
