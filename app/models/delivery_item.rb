class DeliveryItem < ApplicationRecord
  belongs_to :delivery
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validate :product_matches_delivery_business

  private
    def product_matches_delivery_business
      return if delivery.blank? || product.blank?
      return if delivery.business_id == product.business_id

      errors.add(:product, "must belong to the delivery business")
    end
end
