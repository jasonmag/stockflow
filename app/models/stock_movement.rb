class StockMovement < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :product
  belongs_to :from_location, class_name: "Location", optional: true
  belongs_to :to_location, class_name: "Location", optional: true
  belongs_to :reference, polymorphic: true, optional: true

  enum :movement_type, { in: 0, out: 1, transfer: 2, adjustment: 3 }

  validates :occurred_on, :quantity, :movement_type, presence: true
  validates :unit_cost_cents, presence: true, if: :in?
  validates_same_business_of :product, :from_location, :to_location
  validate :unit_cost_decimal_is_valid
  validate :movement_locations_valid
  validate :reference_matches_business

  scope :inward, -> { where(movement_type: :in) }
  scope :outward, -> { where(movement_type: :out) }

  def from_label
    from_location&.name || reference_from_label || "-"
  end

  def to_label
    to_location&.name || reference_to_label || "-"
  end

  def unit_cost_decimal
    return @unit_cost_decimal if defined?(@unit_cost_decimal) && @unit_cost_decimal.present?
    return if unit_cost_cents.blank?

    format("%.4f", unit_cost_cents / 100.0)
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

    def reference_from_label
      case reference
      when Purchase
        reference.supplier&.name
      end
    end

    def reference_to_label
      case reference
      when Delivery
        reference.customer&.name
      end
    end

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

    def reference_matches_business
      return if reference.blank?
      return unless reference.respond_to?(:business_id)
      return if reference.business_id == business_id

      errors.add(:reference, "must belong to the current business")
    end
end
