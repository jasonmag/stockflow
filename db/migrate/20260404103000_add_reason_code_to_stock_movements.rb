class AddReasonCodeToStockMovements < ActiveRecord::Migration[8.0]
  def change
    add_column :stock_movements, :reason_code, :string
    add_index :stock_movements, [ :business_id, :reason_code ]
  end
end
