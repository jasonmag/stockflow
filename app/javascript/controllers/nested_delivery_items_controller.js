import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "overall", "item", "destroyField"]
  static values = { currency: String }

  connect() {
    this.updateOverall()
  }

  add(event) {
    event?.preventDefault()

    const uniqueId = Date.now().toString()
    const content = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uniqueId)
    this.listTarget.insertAdjacentHTML("beforeend", content)
    this.updateOverall()
    this.notifyProductOptionsChanged()
  }

  addFromUnitPrice(event) {
    if (!this.shouldAddRowFromUnitPrice(event)) return

    event.preventDefault()
    this.add()
    this.focusNewestProductInput()
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
    this.notifyProductOptionsChanged()
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

  shouldAddRowFromUnitPrice(event) {
    const isEnter = event.key === "Enter"
    const isForwardTab = event.key === "Tab" && !event.shiftKey
    if (!isEnter && !isForwardTab) return false

    const currentItem = event.target.closest("[data-nested-delivery-items-target='item']")
    if (!currentItem) return false

    return currentItem === this.visibleItems.at(-1)
  }

  focusNewestProductInput() {
    const newestItem = this.visibleItems.at(-1)
    const input = newestItem?.querySelector(".product-lookup-input")
    input?.focus()
  }

  get visibleItems() {
    return Array.from(this.listTarget.querySelectorAll("[data-nested-delivery-items-target='item']")).filter((item) => !item.classList.contains("hidden"))
  }

  notifyProductOptionsChanged() {
    document.dispatchEvent(new CustomEvent("delivery-items:product-changed"))
  }
}
