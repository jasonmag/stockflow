class StockMovement < ApplicationRecord
  belongs_to :business
  belongs_to :product
  belongs_to :from_location, class_name: "Location", optional: true
  belongs_to :to_location, class_name: "Location", optional: true
  belongs_to :reference, polymorphic: true, optional: true

  enum :movement_type, { in: 0, out: 1, transfer: 2, adjustment: 3 }

  validates :occurred_on, :quantity, :movement_type, presence: true
  validates :unit_cost_cents, presence: true, if: :in?
  validate :movement_locations_valid

  scope :inward, -> { where(movement_type: :in) }

  private
    def movement_locations_valid
      case movement_type&.to_sym
      when :in
        errors.add(:to_location, "is required for stock in") if to_location.blank?
        errors.add(:from_location, "must be blank for stock in") if from_location.present?
      when :out
        errors.add(:from_location, "is required for stock out") if from_location.blank?
        errors.add(:to_location, "must be blank for stock out") if to_location.present?
      when :transfer
        errors.add(:from_location, "is required for transfers") if from_location.blank?
        errors.add(:to_location, "is required for transfers") if to_location.blank?
      when :adjustment
        errors.add(:from_location, "or to_location is required for adjustments") if from_location.blank? && to_location.blank?
      end
    end
end
