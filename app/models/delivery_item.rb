class DeliveryItem < ApplicationRecord
  belongs_to :delivery
  belongs_to :product

  validate :unit_price_decimal_is_valid
  validates :quantity, numericality: { greater_than: 0 }
  validate :product_matches_delivery_business

  def unit_price_decimal
    return @unit_price_decimal if defined?(@unit_price_decimal) && @unit_price_decimal.present?
    return if unit_price_cents.blank?

    format("%.2f", unit_price_cents / 100.0)
  end

  def unit_price_decimal=(value)
    @unit_price_decimal = value.to_s

    if @unit_price_decimal.blank?
      self.unit_price_cents = nil
      return
    end

    self.unit_price_cents = (BigDecimal(@unit_price_decimal) * 100).round
    @invalid_unit_price_decimal = false
  rescue ArgumentError
    self.unit_price_cents = nil
    @invalid_unit_price_decimal = true
  end

  private
    def unit_price_decimal_is_valid
      return unless @invalid_unit_price_decimal

      errors.add(:unit_price_decimal, "is not a valid amount")
    end

    def product_matches_delivery_business
      return if delivery.blank? || product.blank?
      return if delivery.business_id == product.business_id

      errors.add(:product, "must belong to the delivery business")
    end
end
