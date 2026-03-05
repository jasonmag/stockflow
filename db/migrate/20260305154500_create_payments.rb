class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :business, null: false, foreign_key: true
      t.references :payable, null: true, foreign_key: true
      t.references :expense, null: true, foreign_key: true
      t.date :paid_on, null: false
      t.integer :amount_cents, null: false
      t.integer :method, null: false, default: 0
      t.text :notes

      t.timestamps
    end
  end
end
