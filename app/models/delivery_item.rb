class DeliveryItem < ApplicationRecord
  belongs_to :delivery
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
end
