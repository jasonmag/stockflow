class Purchase < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :supplier
  belongs_to :receiving_location, class_name: "Location"
  has_one_attached :purchase_image
  has_many :purchase_items, dependent: :destroy
  has_many :stock_movements, as: :reference, dependent: :nullify
  has_one :expense, dependent: :nullify
  accepts_nested_attributes_for :purchase_items, allow_destroy: true, reject_if: :all_blank

  enum :status, { draft: 0, received: 1 }

  before_validation :assign_reference
  before_validation :normalize_funding_source

  validates :purchased_on, :receiving_location, :funding_source, presence: true
  validates :reference, uniqueness: { scope: :business_id }, allow_blank: true
  validates_same_business_of :supplier, :receiving_location
  validate :funding_source_enabled_for_business

  def receive!
    transaction do
      actioned_at = received_at || Time.current

      unless inventory_received?
        purchase_items.find_each do |item|
          StockMovement.create!(
            business:,
            movement_type: :in,
            product: item.product,
            quantity: item.quantity,
            unit_cost_cents: item.unit_cost_cents,
            to_location: receiving_location,
            occurred_on: actioned_at.to_date,
            reference: self,
            notes: "Purchase ##{id} received"
          )
        end
      end

      update!(status: :received, received_at: actioned_at) unless received? && received_at.present?
      sync_expense!
    end
  end

  def inventory_received?
    stock_movements.inward.exists?
  end

  def purchase_image_storage_synced?
    purchase_image_storage_file_id.present? && purchase_image_storage_blob_id == purchase_image.blob_id
  end

  def next_reference
    return if purchased_on.blank? || business.blank?

    self.class.next_reference_for(business:, purchased_on:, excluding_id: id)
  end

  private
    def assign_reference
      self.reference = next_reference
    end

    def normalize_funding_source
      self.funding_source = Business.normalize_purchase_funding_source_label(funding_source)
    end

    def sync_expense!
      purchases_category = business.categories.find_or_create_by!(name: "Purchases")
      generated_expense = expense || build_expense

      generated_expense.assign_attributes(
        business:,
        category: purchases_category,
        occurred_on: purchased_on,
        payee: supplier.name,
        amount_cents: total_amount_cents,
        currency: business.currency,
        funding_source: funding_source,
        payment_method: expense_payment_method,
        notes: "Auto-generated from purchase #{reference.presence || id}"
      )
      generated_expense.save!
    end

    def total_amount_cents
      purchase_items.sum { |item| (item.unit_cost_cents.to_i * item.quantity.to_d).round }
    end

    def expense_payment_method
      business.purchase_funding_source_type_for(funding_source) == "credit" ? :credit : :cash
    end

    def funding_source_enabled_for_business
      return if funding_source.blank? || business.blank?
      return if business.purchase_funding_source_enabled?(funding_source)

      errors.add(:funding_source, "is not enabled in store settings")
    end

    class << self
      def next_reference_for(business:, purchased_on:, excluding_id: nil)
        base_reference = "PO-#{purchased_on}"
        scope = business.purchases.where("reference = ? OR reference LIKE ?", base_reference, "#{base_reference}-%")
        scope = scope.where.not(id: excluding_id) if excluding_id.present?

        existing_references = scope.pluck(:reference)
        sequence = existing_references.filter_map do |reference|
          if reference == base_reference
            1
          else
            match = reference.match(/\A#{Regexp.escape(base_reference)}-(\d+)\z/)
            match && match[1].to_i
          end
        end.max.to_i + 1

        "#{base_reference}-#{sequence}"
      end
    end
end
