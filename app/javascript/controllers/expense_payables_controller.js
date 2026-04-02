import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["category", "payablesSection", "payables", "amount", "payee"]

  connect() {
    this.toggle()
    this.syncAmount()
  }

  toggle() {
    const payablesSelected = this.selectedCategoryName() === "Payables"

    this.payablesSectionTarget.classList.toggle("hidden", !payablesSelected)
    this.amountTarget.readOnly = payablesSelected
    this.amountTarget.classList.toggle("bg-slate-100", payablesSelected)
  }

  syncAmount() {
    if (this.selectedCategoryName() !== "Payables") return

    const selectedOptions = Array.from(this.payablesTarget.selectedOptions)
    const total = selectedOptions.reduce((sum, option) => sum + Number(option.dataset.amountCents || 0), 0)
    const payees = [...new Set(selectedOptions.map((option) => option.text.split(" - ")[0]).filter(Boolean))]

    this.amountTarget.value = (total / 100).toFixed(2)
    this.payeeTarget.value = payees.join(", ")
  }

  selectedCategoryName() {
    return this.categoryTarget.selectedOptions[0]?.dataset.categoryName || ""
  }
}
