class AddCurrencyToBusinesses < ActiveRecord::Migration[8.0]
  def up
    add_column :businesses, :currency, :string, null: false, default: "PHP"

    execute <<~SQL.squish
      UPDATE businesses
      SET currency = 'PHP'
      WHERE currency IS NULL OR TRIM(currency) = ''
    SQL
  end

  def down
    remove_column :businesses, :currency
  end
end
