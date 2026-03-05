class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :categories, [ :business_id, :name ], unique: true
  end
end
