module ApplicationHelper
  def money(cents, currency = "PHP")
    "#{currency} #{format('%.2f', cents.to_f / 100.0)}"
  end
end
