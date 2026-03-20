class ConvertPurchaseFundingSourcesToCustomText < ActiveRecord::Migration[8.0]
  class MigrationBusiness < ActiveRecord::Base
    self.table_name = "businesses"
  end

  class MigrationPurchase < ActiveRecord::Base
    self.table_name = "purchases"
  end

  LEGACY_SOURCE_LABELS = {
    "personal" => "Cash Personal",
    "business" => "Cash Business",
    "cash_personal" => "Cash Personal",
    "cash_business" => "Cash Business",
    "card_personal" => "Card Personal",
    "card_business" => "Card Business"
  }.freeze
  PURCHASE_SOURCE_MAP = {
    0 => "Cash Personal",
    1 => "Cash Business",
    2 => "Card Personal",
    3 => "Card Business"
  }.freeze
  DEFAULT_BUSINESS_SOURCES = [
    "Cash Personal",
    "Cash Business",
    "Card Personal",
    "Card Business"
  ].freeze
  DEFAULT_SOURCE = "Cash Personal".freeze

  def up
    change_column_default :businesses, :purchase_funding_sources, from: "cash_personal\ncash_business\ncard_personal\ncard_business", to: DEFAULT_BUSINESS_SOURCES.join("\n")

    MigrationBusiness.reset_column_information
    MigrationBusiness.find_each do |business|
      labels = business.purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        normalize_business_source(value)
      end.uniq

      business.update_columns(
        purchase_funding_sources: (labels.presence || DEFAULT_BUSINESS_SOURCES).join("\n")
      )
    end

    add_column :purchases, :funding_source_value, :string, null: false, default: DEFAULT_SOURCE

    MigrationPurchase.reset_column_information
    MigrationPurchase.find_each do |purchase|
      purchase.update_columns(
        funding_source_value: PURCHASE_SOURCE_MAP.fetch(purchase[:funding_source], DEFAULT_SOURCE)
      )
    end

    remove_column :purchases, :funding_source, :integer
    rename_column :purchases, :funding_source_value, :funding_source
  end

  def down
    change_column_default :businesses, :purchase_funding_sources, from: DEFAULT_BUSINESS_SOURCES.join("\n"), to: "cash_personal\ncash_business\ncard_personal\ncard_business"

    add_column :purchases, :funding_source_value, :integer, null: false, default: 0

    MigrationPurchase.reset_column_information
    reverse_map = PURCHASE_SOURCE_MAP.invert
    MigrationPurchase.find_each do |purchase|
      purchase.update_columns(
        funding_source_value: reverse_map.fetch(normalize_business_source(purchase[:funding_source]), 0)
      )
    end

    remove_column :purchases, :funding_source, :string
    rename_column :purchases, :funding_source_value, :funding_source

    MigrationBusiness.reset_column_information
    MigrationBusiness.find_each do |business|
      keys = business.purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        LEGACY_SOURCE_LABELS.invert[normalize_business_source(value)]
      end.uniq

      business.update_columns(purchase_funding_sources: (keys.presence || %w[cash_personal cash_business card_personal card_business]).join("\n"))
    end
  end

  private
    def normalize_business_source(value)
      normalized = value.to_s.squish
      return if normalized.blank?

      LEGACY_SOURCE_LABELS.fetch(normalized.downcase, normalized)
    end
end
