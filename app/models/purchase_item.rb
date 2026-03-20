class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validate :unit_cost_decimal_is_valid
  validates :quantity, :unit_cost_cents, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost_cents, numericality: { greater_than: 0 }
  validate :product_matches_purchase_business

  def unit_cost_decimal
    return @unit_cost_decimal if defined?(@unit_cost_decimal) && @unit_cost_decimal.present?
    return if unit_cost_cents.blank?

    format("%.2f", unit_cost_cents / 100.0)
  end

  def unit_cost_decimal=(value)
    @unit_cost_decimal = value.to_s

    if @unit_cost_decimal.blank?
      self.unit_cost_cents = nil
      return
    end

    self.unit_cost_cents = (BigDecimal(@unit_cost_decimal) * 100).round
    @invalid_unit_cost_decimal = false
  rescue ArgumentError
    self.unit_cost_cents = nil
    @invalid_unit_cost_decimal = true
  end

  private
    def unit_cost_decimal_is_valid
      return unless @invalid_unit_cost_decimal

      errors.add(:unit_cost_decimal, "is not a valid amount")
    end

    def product_matches_purchase_business
      return if purchase.blank? || product.blank?
      return if purchase.business_id == product.business_id

      errors.add(:product, "must belong to the purchase business")
    end
end
