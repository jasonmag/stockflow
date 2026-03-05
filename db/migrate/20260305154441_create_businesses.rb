class CreateBusinesses < ActiveRecord::Migration[8.0]
  def change
    create_table :businesses do |t|
      t.string :name, null: false
      t.string :contact_email
      t.string :contact_phone
      t.text :address
      t.integer :reminder_lead_days, null: false, default: 7

      t.timestamps
    end
  end
end
