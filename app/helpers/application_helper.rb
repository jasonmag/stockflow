module ApplicationHelper
  def money(cents, currency = "PHP")
    "#{currency} #{format('%.2f', cents.to_f / 100.0)}"
  end

  def nav_link_to(name, path)
    active = current_page?(path)
    classes = if active
      "rounded-lg bg-slate-900 px-3 py-2 text-sm font-medium text-white"
    else
      "rounded-lg px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-200"
    end
    link_to name, path, class: classes
  end

  def status_badge(status)
    tone = case status.to_s
    when "paid", "collected", "delivered", "sent", "read", "received", "business", "active", "attached", "enabled", "approved"
      "badge-success"
    when "overdue", "late", "failed", "void"
      "badge-danger"
    when "queued", "draft", "pending", "unpaid", "personal", "inactive", "missing", "disabled"
      "badge-warning"
    else
      "badge-neutral"
    end

    content_tag(:span, status.to_s.humanize, class: "badge #{tone}")
  end
end
