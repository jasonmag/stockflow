module MoneyPrecision
  SCALE = 10_000
  FORM_PRECISION = 4
  DISPLAY_MIN_PRECISION = 2

  module_function

  def parse(value)
    (BigDecimal(value.to_s.strip) * SCALE).round(0).to_i
  end

  def to_formatted_decimal(amount)
    format("%.#{FORM_PRECISION}f", amount.to_d / SCALE)
  end

  def to_display_decimal(amount)
    whole, fractional = to_formatted_decimal(amount).split(".")
    fractional = fractional.sub(/0+\z/, "")
    fractional = fractional.ljust(DISPLAY_MIN_PRECISION, "0")
    [whole, fractional].join(".")
  end
end
