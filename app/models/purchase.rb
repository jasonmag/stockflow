class Purchase < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :supplier
  belongs_to :receiving_location, class_name: "Location"
  has_many :purchase_items, dependent: :destroy
  accepts_nested_attributes_for :purchase_items, allow_destroy: true

  enum :status, { draft: 0, received: 1 }

  validates :purchased_on, :receiving_location, :funding_source, presence: true
  validates_same_business_of :supplier, :receiving_location
  validate :funding_source_enabled_for_business

  def receive!
    transaction do
      purchase_items.find_each do |item|
        StockMovement.create!(
          business:,
          movement_type: :in,
          product: item.product,
          quantity: item.quantity,
          unit_cost_cents: item.unit_cost_cents,
          to_location: receiving_location,
          occurred_on: purchased_on,
          reference: self,
          notes: "Purchase ##{id} received"
        )
      end
      update!(status: :received)
    end
  end

  private
    def funding_source_enabled_for_business
      return if funding_source.blank? || business.blank?
      return if business.purchase_funding_source_enabled?(funding_source)

      errors.add(:funding_source, "is not enabled in store settings")
    end
end
