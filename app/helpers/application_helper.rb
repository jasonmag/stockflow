module ApplicationHelper
  def money(cents, currency = nil)
    currency ||= current_business&.currency || "PHP"
    "#{currency} #{format('%.2f', cents.to_f / 100.0)}"
  end

  def nav_link_to(name, path)
    active = current_page?(path)
    classes = if active
      "nav-link nav-link-active"
    else
      "nav-link"
    end
    link_to name, path, class: classes
  end

  def status_badge(status)
    tone = case status.to_s
    when "paid", "collected", "delivered", "sent", "read", "received", "business", "cash_business", "card_business", "active", "attached", "enabled", "approved"
      "badge-success"
    when "overdue", "late", "failed", "void"
      "badge-danger"
    when "queued", "draft", "pending", "unpaid", "personal", "cash_personal", "card_personal", "inactive", "missing", "disabled"
      "badge-warning"
    else
      "badge-neutral"
    end

    content_tag(:span, status.to_s.humanize, class: "badge #{tone}")
  end
end
