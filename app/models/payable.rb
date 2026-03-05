class Payable < ApplicationRecord
  belongs_to :business
  has_many :payments, dependent: :destroy

  enum :payable_type, { supplier: 0, credit_card: 1, loan: 2, rent: 3, utilities: 4, other: 5 }
  enum :status, { unpaid: 0, paid: 1, overdue: 2 }

  validates :payee, :amount_cents, :currency, :due_on, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }

  scope :upcoming, -> { unpaid.where(due_on: Date.current..30.days.from_now.to_date) }
  scope :overdue_list, -> { where(status: %i[unpaid overdue]).where("due_on < ?", Date.current) }

  def refresh_status!
    next_status = paid? ? :paid : (due_on < Date.current ? :overdue : :unpaid)
    update!(status: next_status) unless status.to_sym == next_status
  end
end
