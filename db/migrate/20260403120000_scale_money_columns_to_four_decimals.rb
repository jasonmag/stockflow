class ScaleMoneyColumnsToFourDecimals < ActiveRecord::Migration[8.0]
  TABLE_COLUMNS = {
    collections: %i[amount_cents],
    delivery_items: %i[unit_price_cents],
    expenses: %i[amount_cents],
    payables: %i[amount_cents],
    payments: %i[amount_cents],
    product_prices: %i[price_cents],
    product_purchase_prices: %i[price_cents],
    products: %i[base_cost_cents],
    purchase_items: %i[unit_cost_cents],
    receivables: %i[amount_cents],
    stock_movements: %i[unit_cost_cents]
  }.freeze

  def up
    scale_columns(100)
  end

  def down
    scale_columns(0.01)
  end

  private
    def scale_columns(multiplier)
      TABLE_COLUMNS.each do |table_name, columns|
        columns.each do |column_name|
          execute <<~SQL
            UPDATE #{table_name}
            SET #{column_name} = ROUND(#{column_name} * #{multiplier})
            WHERE #{column_name} IS NOT NULL
          SQL
        end
      end
    end
end
