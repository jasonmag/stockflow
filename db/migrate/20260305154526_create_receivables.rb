class CreateReceivables < ActiveRecord::Migration[8.0]
  def change
    create_table :receivables do |t|
      t.references :business, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :reference
      t.date :delivered_on
      t.date :due_on, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PHP"
      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
