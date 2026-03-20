import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hidden", "input", "menu", "item", "empty", "toggle"]
  static values = {
    placeholder: { type: String, default: "Select product" }
  }

  connect() {
    this.boundOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundOutsideClick)
    this.syncFromHidden()
    this.filter()
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutsideClick)
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
    this.menuTarget.classList.remove("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.menuTarget.classList.add("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let matches = 0

    this.open()

    this.itemTargets.forEach((item) => {
      const visible = item.dataset.label.toLowerCase().includes(query)
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

    this.close()
  }

  syncFromHidden() {
    const selectedId = this.hiddenTarget.value
    const selectedItem = this.itemTargets.find((item) => item.dataset.value === selectedId)

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
}
