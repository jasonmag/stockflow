class Receivable < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :customer
  has_many :collections, dependent: :destroy

  enum :status, { pending: 0, collected: 1, late: 2 }

  before_validation :sync_currency_from_business
  validate :amount_decimal_is_valid

  validates :due_on, :amount_cents, :currency, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates_same_business_of :customer

  scope :due_soon, -> { where(status: :pending, due_on: Date.current..30.days.from_now.to_date) }
  scope :overdue_list, -> { where(status: %i[pending late]).where("due_on < ?", Date.current) }

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

  private
    def amount_decimal_is_valid
      return unless @invalid_amount_decimal

      errors.add(:amount_decimal, "is not a valid amount")
    end

    def sync_currency_from_business
      self.currency = business&.currency if business.present?
    end
end
