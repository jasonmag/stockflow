class Business < ApplicationRecord
  LEGACY_PURCHASE_FUNDING_SOURCE_LABELS = {
    "personal" => "Cash Personal",
    "business" => "Cash Business",
    "cash_personal" => "Cash Personal",
    "cash_business" => "Cash Business",
    "card_personal" => "Card Personal",
    "card_business" => "Card Business"
  }.freeze
  DEFAULT_PURCHASE_FUNDING_SOURCES = [
    "Cash Personal",
    "Cash Business",
    "Card Personal",
    "Card Business"
  ].freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :categories, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :payables, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :receivables, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :deliveries, dependent: :destroy
  has_many :notifications, dependent: :destroy

  before_validation :normalize_purchase_funding_sources

  validates :name, presence: true
  validates :reminder_lead_days, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_funding_sources, presence: true

  def purchase_funding_source_keys
    parsed_purchase_funding_sources.presence || DEFAULT_PURCHASE_FUNDING_SOURCES
  end

  def purchase_funding_source_keys=(values)
    normalized_values = Array(values).filter_map do |value|
      option = normalize_purchase_funding_source(value)
      option if option.present?
    end

    self.purchase_funding_sources = normalized_values.uniq.join("\n")
  end

  def purchase_funding_source_options
    purchase_funding_source_keys.map { |value| [ value, value ] }
  end

  def purchase_funding_source_enabled?(value)
    normalized_value = normalize_purchase_funding_source(value)
    purchase_funding_source_keys.any? { |option| normalize_purchase_funding_source(option) == normalized_value }
  end

  private
    def parsed_purchase_funding_sources
      purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        option = normalize_purchase_funding_source(value)
        option if option.present?
      end.uniq(&:downcase)
    end

    def normalize_purchase_funding_sources
      self.purchase_funding_sources = purchase_funding_source_keys.join("\n")
    end

    def normalize_purchase_funding_source(value)
      normalized = value.to_s.squish
      return if normalized.blank?

      LEGACY_PURCHASE_FUNDING_SOURCE_LABELS.fetch(normalized.downcase, normalized)
    end
end
