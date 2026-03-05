class Collection < ApplicationRecord
  belongs_to :business
  belongs_to :receivable, optional: true

  enum :method, { cash: 0, bank: 1 }

  validates :collected_on, :amount_cents, :method, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
end
