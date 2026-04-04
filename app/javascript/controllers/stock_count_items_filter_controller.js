import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "row"]

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let matchedRows = []

    this.rowTargets.forEach((row) => {
      const haystack = [
        row.dataset.stockCountItemsFilterName,
        row.dataset.stockCountItemsFilterSku,
        row.dataset.stockCountItemsFilterBarcode
      ].join(" ").toLowerCase()
      const visible = query.length === 0 || haystack.includes(query)
      row.classList.toggle("hidden", !visible)
      if (visible) matchedRows.push(row)
    })

    if (query.length > 0 && matchedRows.length === 1) {
      matchedRows[0].querySelector("input[type='number']")?.focus()
    }
  }
}
