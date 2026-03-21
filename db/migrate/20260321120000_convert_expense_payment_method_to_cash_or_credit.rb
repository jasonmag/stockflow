class ConvertExpensePaymentMethodToCashOrCredit < ActiveRecord::Migration[8.0]
  class MigrationExpense < ActiveRecord::Base
    self.table_name = "expenses"
  end

  LEGACY_PAYMENT_METHOD_MAP = {
    0 => "cash",
    1 => "credit",
    2 => "credit"
  }.freeze

  def up
    add_column :expenses, :payment_method_value, :string, null: false, default: "cash" unless column_exists?(:expenses, :payment_method_value)

    MigrationExpense.reset_column_information

    if column_exists?(:expenses, :payment_method) && !column_exists?(:expenses, :payment_method, :string)
      MigrationExpense.find_each do |expense|
        expense.update_columns(payment_method_value: LEGACY_PAYMENT_METHOD_MAP.fetch(expense[:payment_method], "cash"))
      end

      remove_column :expenses, :payment_method, :integer
      rename_column :expenses, :payment_method_value, :payment_method
    end
  end

  def down
    add_column :expenses, :payment_method_value, :integer, null: false, default: 0

    MigrationExpense.reset_column_information
    MigrationExpense.find_each do |expense|
      expense.update_columns(payment_method_value: expense[:payment_method] == "credit" ? 2 : 0)
    end

    remove_column :expenses, :payment_method, :string
    rename_column :expenses, :payment_method_value, :payment_method
  end
end
