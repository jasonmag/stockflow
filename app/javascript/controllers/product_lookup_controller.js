import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hidden", "input", "menu", "item", "empty", "toggle"]
  static values = {
    placeholder: { type: String, default: "Select product" }
  }

  connect() {
    this.boundOutsideClick = this.handleOutsideClick.bind(this)
    this.boundAvailabilityRefresh = this.refreshAvailability.bind(this)
    document.addEventListener("click", this.boundOutsideClick)
    document.addEventListener("delivery-items:product-changed", this.boundAvailabilityRefresh)
    this.syncFromHidden()
    this.filter()
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutsideClick)
    document.removeEventListener("delivery-items:product-changed", this.boundAvailabilityRefresh)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    const selectedItem = this.selectedItem
    const query = selectedItem && this.inputTarget.value === selectedItem.dataset.label ? "" : this.inputTarget.value

    this.filter(query)
    this.menuTarget.classList.remove("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  filter(queryOverride = null) {
    const query = (queryOverride ?? this.inputTarget.value).trim().toLowerCase()
    let matches = 0

    this.itemTargets.forEach((item) => {
      const visible = this.itemMatchesQuery(item, query) && this.itemIsAvailable(item)
      item.classList.toggle("hidden", !visible)
      matches += visible ? 1 : 0
    })

    this.emptyTarget.classList.toggle("hidden", matches > 0)
  }

  select(event) {
    event.preventDefault()
    event.stopPropagation()

    const selectedItem = event.currentTarget
    this.hiddenTarget.value = selectedItem.dataset.value
    this.inputTarget.value = selectedItem.dataset.label

    this.itemTargets.forEach((item) => {
      item.classList.toggle("is-selected", item === selectedItem)
    })

    this.applyUnitPrice(selectedItem.dataset.unitPrice)
    this.dispatchProductChanged()
    this.close()
  }

  syncFromHidden() {
    const selectedItem = this.selectedItem

    this.inputTarget.value = selectedItem?.dataset.label || ""
    this.inputTarget.placeholder = this.placeholderValue
    this.itemTargets.forEach((item) => {
      item.classList.toggle("is-selected", item === selectedItem)
    })
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  refreshAvailability() {
    this.filter()
  }

  dispatchProductChanged() {
    document.dispatchEvent(new CustomEvent("delivery-items:product-changed"))
  }

  applyUnitPrice(unitPrice) {
    const row = this.element.closest("[data-controller~='delivery-item-total']")
    const unitPriceInput = row?.querySelector("[data-delivery-item-total-target='unitPrice']")
    if (!unitPriceInput) return

    unitPriceInput.value = unitPrice || ""
    unitPriceInput.dispatchEvent(new Event("input", { bubbles: true }))
  }

  itemMatchesQuery(item, query) {
    return item.dataset.label.toLowerCase().includes(query)
  }

  itemIsAvailable(item) {
    const selectedIds = this.selectedProductIds
    return !selectedIds.includes(item.dataset.value) || item.dataset.value === this.hiddenTarget.value
  }

  get selectedProductIds() {
    const container = this.element.closest("[data-controller~='nested-delivery-items']")
    if (!container) return []

    return Array.from(container.querySelectorAll("[data-controller~='product-lookup'] [data-product-lookup-target='hidden']"))
      .filter((input) => !input.closest("[data-nested-delivery-items-target='item']")?.classList.contains("hidden"))
      .map((input) => input.value)
      .filter(Boolean)
  }

  get selectedItem() {
    const selectedId = this.hiddenTarget.value
    return this.itemTargets.find((item) => item.dataset.value === selectedId)
  }
}
