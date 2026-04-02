class ProductPrice < ApplicationRecord
  belongs_to :product

  scope :effective_on_or_before, ->(date) { where("effective_on <= ?", date).order(effective_on: :desc, created_at: :desc, id: :desc) }

  validates :effective_on, presence: true, uniqueness: { scope: :product_id }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :price_decimal_presence
  validate :price_decimal_is_valid

  def price_decimal
    return @price_decimal if defined?(@price_decimal) && @price_decimal.present?
    return if price_cents.blank?

    MoneyPrecision.to_formatted_decimal(price_cents)
  end

  def price_decimal=(value)
    @price_decimal = value.to_s

    if @price_decimal.blank?
      self.price_cents = nil
      return
    end

    normalized = @price_decimal.strip
    self.price_cents = MoneyPrecision.parse(normalized)
    @invalid_price_decimal = false
  rescue ArgumentError, TypeError
    self.price_cents = nil
    @invalid_price_decimal = true
  end

  private
    def price_decimal_presence
      return unless price_cents.nil? && !@invalid_price_decimal

      errors.add(:price_decimal, "can't be blank")
    end

    def price_decimal_is_valid
      return unless @invalid_price_decimal

      errors.add(:price_decimal, "is not a valid amount")
    end
end
