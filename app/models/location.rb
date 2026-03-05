class Location < ApplicationRecord
  belongs_to :business
  has_many :from_stock_movements, class_name: "StockMovement", foreign_key: :from_location_id, dependent: :nullify
  has_many :to_stock_movements, class_name: "StockMovement", foreign_key: :to_location_id, dependent: :nullify

  enum :location_type, { home: 0, storage: 1, warehouse: 2, vending: 3, customer: 4, other: 5 }

  validates :name, presence: true
end
