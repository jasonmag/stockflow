class ConvertExpenseFundingSourceToBusinessText < ActiveRecord::Migration[8.0]
  class MigrationBusiness < ActiveRecord::Base
    self.table_name = "businesses"
  end

  class MigrationExpense < ActiveRecord::Base
    self.table_name = "expenses"
  end

  LEGACY_FUNDING_SOURCE_MAP = {
    0 => "Cash",
    1 => "Cash"
  }.freeze

  def up
    add_column :expenses, :funding_source_value, :string, null: false, default: "Cash" unless column_exists?(:expenses, :funding_source_value)

    MigrationBusiness.reset_column_information
    MigrationExpense.reset_column_information

    business_sources = {}
    MigrationBusiness.find_each do |business|
      business_sources[business.id] = parse_sources(business.purchase_funding_sources)
    end

    if column_exists?(:expenses, :funding_source) && !column_exists?(:expenses, :funding_source, :string)
      MigrationExpense.find_each do |expense|
        source_name = preferred_cash_source_for(business_sources[expense.business_id]) || LEGACY_FUNDING_SOURCE_MAP.fetch(expense[:funding_source], "Cash")
        expense.update_columns(funding_source_value: source_name)
      end

      remove_column :expenses, :funding_source, :integer
      rename_column :expenses, :funding_source_value, :funding_source
    end
  end

  def down
    add_column :expenses, :funding_source_value, :integer, null: false, default: 1

    MigrationExpense.reset_column_information
    MigrationExpense.find_each do |expense|
      expense.update_columns(funding_source_value: 1)
    end

    remove_column :expenses, :funding_source, :string
    rename_column :expenses, :funding_source_value, :funding_source
  end

  private
    def parse_sources(raw_sources)
      raw_sources.to_s.split(/[\r\n]+/).filter_map do |value|
        normalized = value.to_s.squish
        next if normalized.blank?

        {
          name: normalized_funding_source_name(normalized),
          source_type: inferred_source_type(normalized)
        }
      end.uniq { |source| source[:name].downcase }
    end

    def normalized_funding_source_name(value)
      case value.downcase
      when "personal", "business", "cash_personal", "cash_business", "cash personal", "cash business"
        "Cash"
      when "card_personal", "card_business", "card personal", "card business"
        "Credit"
      else
        value
      end
    end

    def inferred_source_type(value)
      normalized = value.downcase
      return "credit" if normalized.include?("credit") || normalized.include?("card")

      "cash"
    end

    def preferred_cash_source_for(sources)
      Array(sources).find { |source| source[:source_type] == "cash" }&.dig(:name)
    end
end
