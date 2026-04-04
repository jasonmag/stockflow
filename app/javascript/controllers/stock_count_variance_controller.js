import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actual", "expected", "variance", "reason"]
  static values = { expected: Number }

  connect() {
    this.refresh()
  }

  refresh() {
    const actual = this.actualTarget.value === "" ? null : Number(this.actualTarget.value)
    const variance = actual === null ? 0 : actual - this.expectedValue
    const formatted = Number.isInteger(variance) ? variance.toString() : variance.toFixed(2).replace(/\.?0+$/, "")

    this.varianceTarget.textContent = formatted
    this.element.classList.toggle("bg-amber-50", variance !== 0)
    this.varianceTarget.classList.toggle("font-semibold", variance !== 0)
    this.varianceTarget.classList.toggle("text-amber-700", variance !== 0)
    this.reasonTarget.required = variance !== 0
  }
}
