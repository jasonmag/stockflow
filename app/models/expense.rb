class Expense < ApplicationRecord
  belongs_to :business
  belongs_to :category
  has_one_attached :receipt
  has_many :payments, dependent: :nullify

  enum :funding_source, { personal: 0, business: 1 }
  enum :payment_method, { cash: 0, bank: 1, card: 2 }

  validates :occurred_on, :payee, :amount_cents, :currency, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :receipt, presence: true

  scope :for_month_to_date, -> { where(occurred_on: Date.current.beginning_of_month..Date.current) }
end
