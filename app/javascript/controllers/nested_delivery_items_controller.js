import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "overall", "item", "destroyField"]
  static values = { currency: String }

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

  remove(event) {
    event.preventDefault()

    const item = event.target.closest("[data-nested-delivery-items-target='item']")
    if (!item) return

    const destroyField = item.querySelector("[data-nested-delivery-items-target='destroyField']")

    if (destroyField && item.querySelector("input[name*='[id]']")) {
      destroyField.value = "1"
      item.classList.add("hidden")
    } else {
      item.remove()
    }

    this.updateOverall()
  }

  updateOverall() {
    const subtotalElements = this.listTarget.querySelectorAll("[data-controller~='delivery-item-total']:not(.hidden)")
    const total = Array.from(subtotalElements).reduce((sum, element) => {
      const subtotal = Number.parseFloat(element.dataset.subtotalValue || "0")
      return sum + (Number.isFinite(subtotal) ? subtotal : 0)
    }, 0)

    this.overallTarget.textContent = this.formatCurrency(total)
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-PH", {
      style: "currency",
      currency: this.currencyValue || "PHP"
    }).format(value || 0)
  }
}
