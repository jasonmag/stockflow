class Payment < ApplicationRecord
  belongs_to :business
  belongs_to :payable, optional: true
  belongs_to :expense, optional: true

  enum :method, { cash: 0, bank: 1, card: 2 }

  validates :paid_on, :amount_cents, :method, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
end
