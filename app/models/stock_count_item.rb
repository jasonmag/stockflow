class StockCountItem < ApplicationRecord
  include BusinessScopeValidation

  VARIANCE_REASONS = [
    "Counting Error",
    "Damaged Item",
    "Missing Item",
    "Theft",
    "Supplier Error",
    "Other"
  ].freeze

  belongs_to :stock_count_session
  belongs_to :product

  validates :expected_quantity, presence: true, numericality: true
  validates :actual_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :variance, presence: true, numericality: true
  validates_same_business_of :product
  validate :variance_reason_required_for_variance

  before_validation :compute_variance

  delegate :business, to: :stock_count_session

  def variance_present?
    variance.to_d.nonzero?
  end

  def requires_reason?
    variance_present?
  end

  private
    def compute_variance
      self.variance = if actual_quantity.nil? || expected_quantity.nil?
        0
      else
        actual_quantity.to_d - expected_quantity.to_d
      end
    end

    def variance_reason_required_for_variance
      return unless requires_reason?
      return if variance_reason.present?

      errors.add(:variance_reason, "must be selected when there is a variance")
    end
end
