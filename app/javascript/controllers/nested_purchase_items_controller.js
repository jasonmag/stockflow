import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "overall", "item", "destroyField"]

  connect() {
    this.updateOverall()
  }

  add(event) {
    event?.preventDefault()

    this.appendItem()
  }

  addFromUnitCost(event) {
    if (event.key === "Tab" && event.shiftKey) return

    const item = event.target.closest("[data-nested-purchase-items-target='item']")
    if (!item || !this.readyForNextItem(item)) return

    event.preventDefault()
    const newItem = this.appendItem()
    const productField = newItem?.querySelector("select[name*='[product_id]']")
    productField?.focus()
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest("[data-nested-purchase-items-target='item']")
    if (!item) return

    const destroyField = item.querySelector("[data-nested-purchase-items-target='destroyField']")

    if (destroyField && item.querySelector("input[name*='[id]']")) {
      destroyField.value = "1"
      item.classList.add("hidden")
    } else {
      item.remove()
    }

    this.updateOverall()
  }

  updateOverall() {
    const subtotalElements = this.listTarget.querySelectorAll("[data-controller~='purchase-item-total']:not(.hidden)")
    const total = Array.from(subtotalElements).reduce((sum, element) => {
      const subtotal = Number.parseFloat(element.dataset.subtotalValue || "0")
      return sum + (Number.isFinite(subtotal) ? subtotal : 0)
    }, 0)

    this.overallTarget.textContent = this.formatCurrency(total)
  }

  appendItem() {
    const uniqueId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const content = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uniqueId)
    this.listTarget.insertAdjacentHTML("beforeend", content)
    this.updateOverall()

    return this.listTarget.querySelector("[data-nested-purchase-items-target='item']:last-of-type")
  }

  readyForNextItem(item) {
    const productId = item.querySelector("select[name*='[product_id]']")?.value?.trim()
    const quantity = item.querySelector("input[name*='[quantity]']")?.value?.trim()
    const unitCost = item.querySelector("input[name*='[unit_cost_decimal]']")?.value?.trim()

    return productId && quantity && unitCost
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-PH", {
      style: "currency",
      currency: "PHP"
    }).format(value || 0)
  }
}
