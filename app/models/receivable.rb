class Receivable < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :customer
  has_many :collections, dependent: :destroy

  enum :status, { pending: 0, collected: 1, late: 2 }

  validates :due_on, :amount_cents, :currency, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates_same_business_of :customer

  scope :due_soon, -> { where(status: :pending, due_on: Date.current..30.days.from_now.to_date) }
  scope :overdue_list, -> { where(status: %i[pending late]).where("due_on < ?", Date.current) }
end
