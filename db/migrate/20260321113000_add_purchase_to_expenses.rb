class AddPurchaseToExpenses < ActiveRecord::Migration[8.0]
  def up
    add_reference :expenses, :purchase, foreign_key: true, index: { unique: true } unless column_exists?(:expenses, :purchase_id)
  end

  def down
    remove_reference :expenses, :purchase, foreign_key: true if column_exists?(:expenses, :purchase_id)
  end
end
