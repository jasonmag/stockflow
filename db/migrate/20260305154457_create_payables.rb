class CreatePayables < ActiveRecord::Migration[8.0]
  def change
    create_table :payables do |t|
      t.references :business, null: false, foreign_key: true
      t.integer :payable_type, null: false, default: 0
      t.string :payee, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PHP"
      t.date :due_on, null: false
      t.integer :status, null: false, default: 0
      t.text :notes
      t.string :recurring_rule

      t.timestamps
    end
  end
end
