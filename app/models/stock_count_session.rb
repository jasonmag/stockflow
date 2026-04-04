class StockCountSession < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :location, optional: true
  belongs_to :created_by, class_name: "User"
  belongs_to :performed_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :stock_count_items, dependent: :destroy
  has_many :inventory_adjustments, dependent: :destroy
  has_many :stock_count_events, dependent: :destroy
  has_many :stock_movements, as: :reference, dependent: :nullify
  accepts_nested_attributes_for :stock_count_items

  enum :count_type, { end_of_day: 0, weekly: 1, monthly: 2, custom: 3 }
  enum :status, { draft: 0, in_progress: 1, completed: 2, approved: 3 }

  before_validation :assign_reference_number, on: :create
  before_validation :assign_started_at, on: :create
  before_validation :assign_single_location

  validates :reference_number, uniqueness: { scope: :business_id }
  validates :count_date, :count_time, :count_type, :status, :started_at, presence: true
  validates_same_business_of :location
  validate :location_required_for_multi_location_business
  validate :completed_session_requires_actuals, if: :completed_or_approved?

  scope :recent_first, -> { order(count_date: :desc, count_time: :desc, created_at: :desc, id: :desc) }

  def locked?
    completed? || approved?
  end

  def completed_or_approved?
    completed? || approved?
  end

  def variances_count
    stock_count_items.select(&:variance_present?).count
  end

  def total_variance_quantity
    stock_count_items.sum { |item| item.variance.to_d.abs }
  end

  def display_location
    location&.name || "All locations"
  end

  def self.next_reference_for(business:)
    prefix = "MC-#{Date.current.strftime('%Y%m%d')}"
    last_reference = business.stock_count_sessions.where("reference_number LIKE ?", "#{prefix}-%").order(:reference_number).last&.reference_number
    sequence = last_reference.to_s.split("-").last.to_i + 1
    format("%<prefix>s-%<sequence>04d", prefix:, sequence:)
  end

  private
    def assign_reference_number
      self.reference_number ||= self.class.next_reference_for(business:)
    end

    def assign_started_at
      self.started_at ||= Time.current
    end

    def assign_single_location
      self.location ||= business.locations.first if business.present? && business.locations.count == 1
    end

    def location_required_for_multi_location_business
      return unless business.present?
      return if location.present?
      return if business.locations.count <= 1

      errors.add(:location, "is required when your business tracks more than one location")
    end

    def completed_session_requires_actuals
      missing_count = stock_count_items.count { |item| item.actual_quantity.nil? }
      errors.add(:base, "Session cannot be completed with missing quantities") if missing_count.positive?
    end
end
