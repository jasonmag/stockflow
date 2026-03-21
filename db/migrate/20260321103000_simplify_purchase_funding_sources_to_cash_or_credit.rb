class SimplifyPurchaseFundingSourcesToCashOrCredit < ActiveRecord::Migration[8.0]
  class MigrationBusiness < ActiveRecord::Base
    self.table_name = "businesses"
  end

  class MigrationPurchase < ActiveRecord::Base
    self.table_name = "purchases"
  end

  LEGACY_SOURCE_LABELS = {
    "personal" => "Cash",
    "business" => "Cash",
    "cash" => "Cash",
    "credit" => "Credit",
    "cash_personal" => "Cash",
    "cash_business" => "Cash",
    "card_personal" => "Credit",
    "card_business" => "Credit",
    "cash personal" => "Cash",
    "cash business" => "Cash",
    "card personal" => "Credit",
    "card business" => "Credit"
  }.freeze
  DEFAULT_BUSINESS_SOURCES = [ "Cash", "Credit" ].freeze
  DEFAULT_SOURCE = "Cash".freeze

  def up
    change_column_default :businesses, :purchase_funding_sources, from: "Cash Personal\nCash Business\nCard Personal\nCard Business", to: DEFAULT_BUSINESS_SOURCES.join("\n")
    change_column_default :purchases, :funding_source, from: "Cash Personal", to: DEFAULT_SOURCE

    MigrationBusiness.reset_column_information
    MigrationBusiness.find_each do |business|
      normalized_sources = business.purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        normalize_source(value)
      end.uniq

      business.update_columns(purchase_funding_sources: (normalized_sources.presence || DEFAULT_BUSINESS_SOURCES).join("\n"))
    end

    MigrationPurchase.reset_column_information
    MigrationPurchase.find_each do |purchase|
      purchase.update_columns(funding_source: normalize_source(purchase.funding_source) || DEFAULT_SOURCE)
    end
  end

  def down
    change_column_default :businesses, :purchase_funding_sources, from: DEFAULT_BUSINESS_SOURCES.join("\n"), to: "Cash Personal\nCash Business\nCard Personal\nCard Business"
    change_column_default :purchases, :funding_source, from: DEFAULT_SOURCE, to: "Cash Personal"
  end

  private
    def normalize_source(value)
      normalized = value.to_s.squish
      return if normalized.blank?

      LEGACY_SOURCE_LABELS.fetch(normalized.downcase, normalized)
    end
end
