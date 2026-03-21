import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "overall"]

  connect() {
    this.updateOverall()
  }

  add(event) {
    event.preventDefault()

    const uniqueId = Date.now().toString()
    const content = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uniqueId)
    this.listTarget.insertAdjacentHTML("beforeend", content)
    this.updateOverall()
  }

  updateOverall() {
    const subtotalElements = this.listTarget.querySelectorAll("[data-controller~='purchase-item-total']")
    const total = Array.from(subtotalElements).reduce((sum, element) => {
      const subtotal = Number.parseFloat(element.dataset.subtotalValue || "0")
      return sum + (Number.isFinite(subtotal) ? subtotal : 0)
    }, 0)

    this.overallTarget.textContent = this.formatCurrency(total)
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-PH", {
      style: "currency",
      currency: "PHP"
    }).format(value || 0)
  }
}
