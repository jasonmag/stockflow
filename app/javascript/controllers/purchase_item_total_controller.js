import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "unitCost", "subtotal"]

  connect() {
    this.update()
  }

  update() {
    const quantity = Number.parseFloat(this.quantityTarget.value || "0")
    const unitCost = Number.parseFloat(this.unitCostTarget.value || "0")
    const subtotal = Number.isFinite(quantity) && Number.isFinite(unitCost) ? quantity * unitCost : 0

    this.subtotalTarget.textContent = this.formatCurrency(subtotal)
    this.element.dataset.subtotalValue = subtotal.toString()
    this.notifyOverallTotal()
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-PH", {
      style: "currency",
      currency: "PHP"
    }).format(value || 0)
  }

  notifyOverallTotal() {
    const container = this.element.closest("[data-controller~='nested-purchase-items']")
    if (!container) return

    container.dispatchEvent(new CustomEvent("purchase-items:recalculate", { bubbles: true }))
  }
}
