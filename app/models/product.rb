class Product < ApplicationRecord
  belongs_to :business
  has_many :stock_movements, dependent: :destroy

  validates :name, :unit, presence: true

  def weighted_average_cost_cents
    ins = stock_movements.inward.where.not(unit_cost_cents: nil)
    qty = ins.sum(:quantity).to_f
    return 0 if qty <= 0

    (ins.sum("quantity * unit_cost_cents") / qty).round
  end
end
