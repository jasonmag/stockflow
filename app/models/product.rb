class Product < ApplicationRecord
  belongs_to :business
  has_many :stock_movements, dependent: :destroy

  before_validation :assign_generated_sku, on: :create

  validates :name, :unit, :inventory_type, :sku, presence: true
  validates :sku, uniqueness: { case_sensitive: false }
  validates :base_cost_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :barcode, uniqueness: { scope: :business_id }, allow_blank: true
  validate :base_cost_decimal_format, if: -> { @base_cost_decimal_input.present? }

  def weighted_average_cost_cents
    ins = stock_movements.inward.where.not(unit_cost_cents: nil)
    qty = ins.sum(:quantity).to_f
    return 0 if qty <= 0

    (ins.sum("quantity * unit_cost_cents") / qty).round
  end

  def base_cost_decimal
    return if base_cost_cents.nil?

    format("%.4f", base_cost_cents.to_f / 100.0)
  end

  def base_cost_decimal=(value)
    @base_cost_decimal_input = value
    return self.base_cost_cents = nil if value.blank?

    normalized = value.to_s.strip
    if normalized.match?(/\A\d{1,8}(\.\d{1,4})?\z/)
      self.base_cost_cents = (BigDecimal(normalized) * 100).round(0).to_i
      @invalid_base_cost_decimal = false
    else
      @invalid_base_cost_decimal = true
    end
  end

  private
    def assign_generated_sku
      return if sku.present?

      self.sku = generate_unique_sku
    end

    def generate_unique_sku
      candidate = "SKU#{SecureRandom.hex(24).upcase}"
      candidate = "SKU#{SecureRandom.hex(24).upcase}" while Product.exists?(sku: candidate)
      candidate
    end

    def base_cost_decimal_format
      return unless @invalid_base_cost_decimal

      errors.add(:base_cost_decimal, "must follow 00000.0000 style decimal format.")
    end
end
