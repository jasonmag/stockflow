import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "unitPrice", "subtotal"]
  static values = { currency: String }

  connect() {
    this.update()
  }

  update() {
    const quantity = Number.parseFloat(this.quantityTarget.value || "0")
    const unitPrice = Number.parseFloat(this.unitPriceTarget.value || "0")
    const subtotal = Number.isFinite(quantity) && Number.isFinite(unitPrice) ? quantity * unitPrice : 0

    this.subtotalTarget.textContent = this.formatCurrency(subtotal)
    this.element.dataset.subtotalValue = subtotal.toString()
    this.notifyOverallTotal()
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-PH", {
      style: "currency",
      currency: this.currencyValue || "PHP"
    }).format(value || 0)
  }

  notifyOverallTotal() {
    const container = this.element.closest("[data-controller~='nested-delivery-items']")
    if (!container) return

    container.dispatchEvent(new CustomEvent("delivery-items:recalculate", { bubbles: true }))
  }
}
