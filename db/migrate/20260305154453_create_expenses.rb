class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :business, null: false, foreign_key: true
      t.date :occurred_on, null: false
      t.string :payee, null: false
      t.references :category, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "PHP"
      t.integer :funding_source, null: false, default: 0
      t.integer :payment_method, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
