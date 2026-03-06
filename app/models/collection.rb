class Collection < ApplicationRecord
  include BusinessScopeValidation

  belongs_to :business
  belongs_to :receivable, optional: true

  enum :method, { cash: 0, bank: 1 }

  validates :collected_on, :amount_cents, :method, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
  validates_same_business_of :receivable
end
