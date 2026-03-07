class AddRegistrationApprovalToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :approved, :boolean, null: false, default: true
    add_column :users, :approved_at, :datetime
    add_reference :users, :approved_by, foreign_key: { to_table: :users }
    add_index :users, :approved
  end
end
