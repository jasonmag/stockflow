class AddExpenseToPayables < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:payables, :expense_id)
      add_reference :payables, :expense, foreign_key: true, index: false
    end

    add_foreign_key :payables, :expenses unless foreign_key_exists?(:payables, :expenses)

    unless index_exists?(:payables, :expense_id, name: :index_payables_on_expense_id)
      add_index :payables, :expense_id, unique: true
    end
  end

  def down
    remove_foreign_key :payables, :expenses if foreign_key_exists?(:payables, :expenses)
    remove_reference :payables, :expense if column_exists?(:payables, :expense_id)
  end
end
