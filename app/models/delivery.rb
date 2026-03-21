class Delivery < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :customer
  belongs_to :from_location, class_name: "Location", optional: true
  has_many :delivery_items, dependent: :destroy
  has_many :delivery_email_logs, dependent: :destroy
  has_many :stock_movements, as: :reference, dependent: :nullify
  has_one_attached :report_pdf
  accepts_nested_attributes_for :delivery_items, allow_destroy: true

  enum :status, { draft: 0, delivered: 1, void: 2 }

  validates :delivery_number, :delivered_on, presence: true
  validates_same_business_of :customer, :from_location

  before_validation :assign_delivery_number, on: :create

  def mark_delivered!
    if from_location.blank?
      errors.add(:from_location, "must be present")
      raise ActiveRecord::RecordInvalid, self
    end
    validator = Inventory::StockValidator.new(delivery: self)
    unless validator.valid?
      errors.add(:base, validator.error_message)
      raise ActiveRecord::RecordInvalid, self
    end

    transaction do
      delivery_items.each do |item|
        StockMovement.create!(
          business:,
          movement_type: :out,
          product: item.product,
          quantity: item.quantity,
          from_location:,
          occurred_on: delivered_on,
          reference: self,
          notes: "Delivery #{delivery_number} to #{customer.name}"
        )
      end
      update!(status: :delivered)
    end
  end

  def voidable?
    !delivered?
  end

  def inventory_delivered?
    stock_movements.outward.exists?
  end

  def delivery_number_preview
    delivery_number.presence || "Auto-generated on save"
  end

  private
    def assign_delivery_number
      return if delivery_number.present?

      year = Date.current.year
      last = business.deliveries.where("delivery_number LIKE ?", "DR-#{year}-%").order(:delivery_number).last
      seq = last&.delivery_number&.split("-")&.last.to_i + 1
      self.delivery_number = format("DR-%<year>d-%<seq>06d", year:, seq:)
    end
end
