module ApplicationHelper
  def money(cents, currency = nil)
    currency ||= current_business&.currency || "PHP"
    "#{currency} #{format('%.2f', cents.to_f / 100.0)}"
  end

  def page_title
    content_for(:title).presence || "Stockflow"
  end

  def meta_description
    content_for(:meta_description).presence || "Stockflow helps supplier teams manage inventory, purchasing, deliveries, receivables, payables, and cashflow from one operational workspace."
  end

  def meta_image_url
    absolute_public_url("/share-card.png")
  end

  def canonical_url
    request.original_url
  end

  def absolute_public_url(path)
    URI.join(request.base_url, path).to_s
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
