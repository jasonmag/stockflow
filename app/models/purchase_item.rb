class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validates :quantity, :unit_cost_cents, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost_cents, numericality: { greater_than: 0 }
  validate :product_matches_purchase_business

  private
    def product_matches_purchase_business
      return if purchase.blank? || product.blank?
      return if purchase.business_id == product.business_id

      errors.add(:product, "must belong to the purchase business")
    end
end
