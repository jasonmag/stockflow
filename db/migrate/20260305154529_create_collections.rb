class CreateCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :collections do |t|
      t.references :business, null: false, foreign_key: true
      t.references :receivable, null: true, foreign_key: true
      t.date :collected_on, null: false
      t.integer :amount_cents, null: false
      t.integer :method, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
