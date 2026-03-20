class ExpandPurchaseFundingSources < ActiveRecord::Migration[8.0]
  class MigrationBusiness < ActiveRecord::Base
    self.table_name = "businesses"
  end

  LEGACY_TO_EXPANDED = {
    "personal" => "cash_personal",
    "business" => "cash_business",
    "cash_personal" => "cash_personal",
    "cash_business" => "cash_business",
    "card_personal" => "card_personal",
    "card_business" => "card_business"
  }.freeze

  NEW_DEFAULT = "cash_personal\ncash_business\ncard_personal\ncard_business".freeze
  OLD_DEFAULT = "personal\nbusiness".freeze

  def up
    change_column_default :businesses, :purchase_funding_sources, from: OLD_DEFAULT, to: NEW_DEFAULT

    MigrationBusiness.reset_column_information
    MigrationBusiness.find_each do |business|
      keys = business.purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        LEGACY_TO_EXPANDED[value.to_s.strip.downcase]
      end.uniq

      business.update_columns(purchase_funding_sources: (keys.presence || NEW_DEFAULT.split("\n")).join("\n"))
    end
  end

  def down
    change_column_default :businesses, :purchase_funding_sources, from: NEW_DEFAULT, to: OLD_DEFAULT

    MigrationBusiness.reset_column_information
    MigrationBusiness.find_each do |business|
      keys = business.purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        case value.to_s.strip.downcase
        when "cash_personal", "card_personal"
          "personal"
        when "cash_business", "card_business"
          "business"
        end
      end.uniq

      business.update_columns(purchase_funding_sources: (keys.presence || OLD_DEFAULT.split("\n")).join("\n"))
    end
  end
end
