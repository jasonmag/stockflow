import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fundingSource", "paymentMethod"]

  connect() {
    this.sync()
  }

  sync() {
    const selectedOption = this.fundingSourceTarget.selectedOptions[0]
    const sourceType = selectedOption?.dataset.sourceType || "cash"
    const normalizedType = sourceType === "credit" ? "credit" : "cash"
    const label = normalizedType === "credit" ? "Credit" : "Cash"

    this.paymentMethodTarget.innerHTML = ""

    const option = document.createElement("option")
    option.value = normalizedType
    option.textContent = label
    option.selected = true

    this.paymentMethodTarget.append(option)
    this.paymentMethodTarget.value = normalizedType
  }
}
