class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.text :address

      t.timestamps
    end
  end
end
