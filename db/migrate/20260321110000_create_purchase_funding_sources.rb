class CreatePurchaseFundingSources < ActiveRecord::Migration[8.0]
  class MigrationBusiness < ActiveRecord::Base
    self.table_name = "businesses"
  end

  class MigrationPurchaseFundingSource < ActiveRecord::Base
    self.table_name = "purchase_funding_sources"
  end

  DEFAULT_SOURCES = [
    { name: "Cash", source_type: "cash" },
    { name: "Credit", source_type: "credit" }
  ].freeze

  def up
    create_table :purchase_funding_sources do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false
      t.string :source_type, null: false

      t.timestamps
    end

    add_index :purchase_funding_sources, [ :business_id, :name ], unique: true

    MigrationBusiness.reset_column_information
    MigrationPurchaseFundingSource.reset_column_information

    MigrationBusiness.find_each do |business|
      sources = parse_sources(business.purchase_funding_sources)
      sources = DEFAULT_SOURCES if sources.empty?

      sources.each do |source|
        MigrationPurchaseFundingSource.create!(
          business_id: business.id,
          name: source[:name],
          source_type: source[:source_type]
        )
      end
    end
  end

  def down
    drop_table :purchase_funding_sources
  end

  private
    def parse_sources(raw_sources)
      raw_sources.to_s.split(/[\r\n]+/).filter_map do |value|
        normalized_name = value.to_s.squish
        next if normalized_name.blank?

        {
          name: normalized_funding_source_name(normalized_name),
          source_type: inferred_source_type(normalized_name)
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
end
