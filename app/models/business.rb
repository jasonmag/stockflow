class Business < ApplicationRecord
  DEFAULT_PURCHASE_FUNDING_SOURCES = %w[cash_personal cash_business card_personal card_business].freeze

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
  validate :purchase_funding_sources_are_supported

  def purchase_funding_source_keys
    parsed_purchase_funding_sources.presence || DEFAULT_PURCHASE_FUNDING_SOURCES
  end

  def purchase_funding_source_keys=(values)
    normalized_values = Array(values).filter_map do |value|
      key = value.to_s.strip.downcase
      key if key.present?
    end

    self.purchase_funding_sources = normalized_values.uniq.join("\n")
  end

  def purchase_funding_source_options
    purchase_funding_source_keys.map { |key| [ purchase_funding_source_label(key), key ] }
  end

  def purchase_funding_source_enabled?(value)
    purchase_funding_source_keys.include?(value.to_s)
  end

  def purchase_funding_source_label(value)
    value.to_s.tr("_", " ").titleize
  end

  private
    def parsed_purchase_funding_sources
      purchase_funding_sources.to_s.split(/[\r\n,]+/).filter_map do |value|
        key = value.to_s.strip.downcase
        key if key.present?
      end.uniq
    end

    def normalize_purchase_funding_sources
      self.purchase_funding_sources = purchase_funding_source_keys.join("\n")
    end

    def purchase_funding_sources_are_supported
      unsupported_values = parsed_purchase_funding_sources - DEFAULT_PURCHASE_FUNDING_SOURCES
      return if unsupported_values.empty?

      errors.add(:purchase_funding_sources, "contains unsupported values: #{unsupported_values.join(', ')}")
    end
end
