class Expense < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :category
  belongs_to :purchase, optional: true
  has_one :payable, dependent: :destroy
  has_one_attached :receipt
  has_many :payments, dependent: :nullify
  has_many :covered_payables, through: :payments, source: :payable

  enum :payment_method, { cash: "cash", credit: "credit" }

  attr_writer :payable_ids

  validate :amount_decimal_is_valid

  before_validation :sync_currency_from_business
  before_validation :sync_payment_method_from_funding_source
  before_validation :sync_payables_expense_attributes
  after_save :sync_payable_payments!
  after_commit :sync_payable_for_credit_expense!, on: %i[create update]

  validates :occurred_on, :payee, :amount_cents, :currency, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :funding_source, presence: true
  validates :payment_method, presence: true
  validates :receipt, presence: true, unless: :purchase_id?
  validates_same_business_of :category
  validate :covered_payables_present_for_payables_category
  validate :covered_payables_belong_to_business

  scope :for_month_to_date, -> { where(occurred_on: Date.current.beginning_of_month..Date.current) }

  def payable_ids
    @payable_ids || payments.where.not(payable_id: nil).pluck(:payable_id).map(&:to_s)
  end

  def amount_decimal
    return @amount_decimal if defined?(@amount_decimal) && @amount_decimal.present?
    return if amount_cents.blank?

    MoneyPrecision.to_formatted_decimal(amount_cents)
  end

  def amount_decimal=(value)
    @amount_decimal = value.to_s

    if @amount_decimal.blank?
      self.amount_cents = nil
      return
    end

    self.amount_cents = MoneyPrecision.parse(@amount_decimal)
    @invalid_amount_decimal = false
  rescue ArgumentError, TypeError
    self.amount_cents = nil
    @invalid_amount_decimal = true
  end

  def receipt_storage_synced?
    receipt_storage_file_id.present? && receipt_storage_blob_id == receipt.blob_id
  end

  private
    def amount_decimal_is_valid
      return unless @invalid_amount_decimal

      errors.add(:amount_decimal, "is not a valid amount")
    end

    def sync_currency_from_business
      self.currency = business&.currency if business.present?
    end

    def sync_payment_method_from_funding_source
      return if funding_source.blank? || business.blank?

      self.payment_method = business.purchase_funding_source_type_for(funding_source) || "cash"
    end

    def sync_payables_expense_attributes
      return unless payables_category?
      return if selected_covered_payables.empty?

      self.amount_cents = selected_covered_payables.sum(&:amount_cents)
      self.payee = selected_covered_payables.map(&:payee).uniq.join(", ")
    end

    def sync_payable_payments!
      existing_payments = payments.includes(:payable).where.not(payable_id: nil).index_by(&:payable_id)
      desired_payables = payables_category? ? selected_covered_payables.index_by(&:id) : {}

      (existing_payments.keys - desired_payables.keys).each do |payable_id|
        payment = existing_payments[payable_id]
        payable = payment.payable
        payment.destroy!
        payable&.refresh_status!
      end

      desired_payables.each do |payable_id, covered_payable|
        payment = existing_payments[payable_id] || payments.build(business:, payable: covered_payable)
        payment.assign_attributes(
          paid_on: occurred_on,
          amount_cents: covered_payable.amount_cents,
          method: payment_method == "credit" ? :card : :cash,
          notes: "Covered by expense #{id}"
        )
        payment.save!
        covered_payable.refresh_status!
      end
    end

    def sync_payable_for_credit_expense!
      if credit?
        generated_payable = payable || build_payable
        generated_payable.assign_attributes(
          business:,
          payable_type: :credit_card,
          payee: payee,
          amount_cents: amount_cents,
          currency: currency,
          due_on: occurred_on,
          status: :unpaid,
          notes: "Auto-generated from expense #{id}"
        )
        generated_payable.save!
      elsif payable.present? && payable.payments.none?
        payable.destroy
      end
    end

    def covered_payables_present_for_payables_category
      return unless payables_category?
      return if selected_covered_payables.any?

      errors.add(:base, "Select at least one payable to cover")
    end

    def covered_payables_belong_to_business
      return if normalized_payable_ids.empty? || business.blank?
      return if selected_covered_payables.size == normalized_payable_ids.size

      errors.add(:base, "Selected payables are invalid")
    end

    def payables_category?
      category&.name == "Payables"
    end

    def selected_covered_payables
      return [] if business.blank? || normalized_payable_ids.empty?

      @selected_covered_payables ||= business.payables.where(id: normalized_payable_ids).to_a
    end

    def normalized_payable_ids
      @normalized_payable_ids ||= Array(@payable_ids).reject(&:blank?).map(&:to_i).uniq
    end
end
