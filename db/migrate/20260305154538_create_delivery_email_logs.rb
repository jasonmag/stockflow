class CreateDeliveryEmailLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_email_logs do |t|
      t.references :delivery, null: false, foreign_key: true
      t.references :sent_by_user, null: false, foreign_key: { to_table: :users }
      t.text :recipients
      t.string :subject
      t.text :message
      t.datetime :sent_at
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end
  end
end
