class InventoryAdjustment < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :product
  belongs_to :stock_count_session
  belongs_to :created_by, class_name: "User"

  validates :adjustment_quantity, presence: true, numericality: { other_than: 0 }
  validates :reason, presence: true
  validates_same_business_of :product
end
