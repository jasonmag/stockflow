class Business < ApplicationRecord
  SUPPORTED_CURRENCIES = %w[PHP USD EUR GBP JPY SGD AUD CAD].freeze
  LEGACY_PURCHASE_FUNDING_SOURCE_LABELS = {
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
  DEFAULT_PURCHASE_FUNDING_SOURCES = [
    "Cash",
    "Credit"
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
  has_many :purchase_funding_sources, dependent: :destroy
  has_many :suppliers, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :receivables, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :deliveries, dependent: :destroy
  has_many :notifications, dependent: :destroy

  after_create_commit :ensure_default_purchase_funding_sources!

  validates :name, presence: true
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :reminder_lead_days, numericality: { greater_than_or_equal_to: 0 }

  def currency_options
    SUPPORTED_CURRENCIES.map { |currency| [ currency, currency ] }
  end

  def purchase_funding_source_keys
    purchase_funding_source_names.presence || DEFAULT_PURCHASE_FUNDING_SOURCES
  end

  def purchase_funding_source_keys=(values)
    normalized_values = Array(values).filter_map do |value|
      option = normalize_purchase_funding_source(value)
      option if option.present?
    end

    sync_purchase_funding_sources!(normalized_values.uniq)
  end

  def purchase_funding_source_options
    purchase_funding_source_keys.map { |value| [ value, value ] }
  end

  def purchase_funding_source_enabled?(value)
    normalized_value = self.class.normalize_purchase_funding_source_label(value)
    purchase_funding_source_keys.any? { |option| normalize_purchase_funding_source(option) == normalized_value }
  end

  def purchase_funding_source_type_for(value)
    normalized_value = self.class.normalize_purchase_funding_source_label(value)
    purchase_funding_sources.find_by(name: normalized_value)&.source_type
  end

  def purchase_funding_source_names_for(source_type)
    purchase_funding_sources.public_send(source_type).pluck(:name)
  end

  def self.normalize_purchase_funding_source_label(value)
    normalized = value.to_s.squish
    return if normalized.blank?

    LEGACY_PURCHASE_FUNDING_SOURCE_LABELS.fetch(normalized.downcase, normalized)
  end

  private
    def normalize_purchase_funding_source(value)
      self.class.normalize_purchase_funding_source_label(value)
    end

    def purchase_funding_source_names
      purchase_funding_sources.order(:name).pluck(:name)
    end

    def sync_purchase_funding_sources!(names)
      desired_names = names.presence || DEFAULT_PURCHASE_FUNDING_SOURCES

      if persisted?
        existing_sources = purchase_funding_sources.index_by { |source| source.name.downcase }
        keep_names = desired_names.map(&:downcase)

        purchase_funding_sources.each do |source|
          source.destroy unless keep_names.include?(source.name.downcase)
        end

        desired_names.each do |name|
          key = name.downcase
          source = existing_sources[key] || purchase_funding_sources.build(name:)
          source.name = name
          source.source_type = inferred_source_type_for(name)
          source.save! if source.new_record? || source.changed?
        end
      else
        @pending_purchase_funding_source_names = desired_names
      end
    end

    def ensure_default_purchase_funding_sources!
      desired_names = @pending_purchase_funding_source_names.presence || DEFAULT_PURCHASE_FUNDING_SOURCES
      sync_purchase_funding_sources!(desired_names) if purchase_funding_sources.empty?
      @pending_purchase_funding_source_names = nil
    end

    def inferred_source_type_for(name)
      normalized_name = name.to_s.downcase
      return "credit" if normalized_name.include?("credit") || normalized_name.include?("card")

      "cash"
    end
end
