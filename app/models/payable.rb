class Payable < ApplicationRecord
  belongs_to :business
  belongs_to :expense, optional: true
  has_many :payments, dependent: :destroy

  enum :payable_type, { supplier: 0, credit_card: 1, loan: 2, rent: 3, utilities: 4, other: 5 }
  enum :status, { unpaid: 0, paid: 1, overdue: 2 }

  before_validation :sync_currency_from_business
  validate :amount_decimal_is_valid

  validates :payee, :amount_cents, :currency, :due_on, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }

  scope :upcoming, -> { unpaid.where(due_on: Date.current..30.days.from_now.to_date) }
  scope :overdue_list, -> { where(status: %i[unpaid overdue]).where("due_on < ?", Date.current) }

  def paid_in_full?
    payments.sum(:amount_cents) >= amount_cents
  end

  def amount_decimal
    return @amount_decimal if defined?(@amount_decimal) && @amount_decimal.present?
    return if amount_cents.blank?

    format("%.4f", amount_cents / 100.0)
  end

  def amount_decimal=(value)
    @amount_decimal = value.to_s

    if @amount_decimal.blank?
      self.amount_cents = nil
      return
    end

    self.amount_cents = (BigDecimal(@amount_decimal) * 100).round
    @invalid_amount_decimal = false
  rescue ArgumentError
    self.amount_cents = nil
    @invalid_amount_decimal = true
  end

  def refresh_status!
    next_status = paid_in_full? ? :paid : (due_on < Date.current ? :overdue : :unpaid)
    update!(status: next_status) unless status.to_sym == next_status
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
