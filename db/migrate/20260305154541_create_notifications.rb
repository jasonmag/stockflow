class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.string :message, null: false
      t.date :due_on, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
