import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row", "empty"]

  connect() {
    this.filter()
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let visibleRows = 0

    this.rowTargets.forEach((row) => {
      const matches = row.dataset.searchText.toLowerCase().includes(query)
      row.classList.toggle("hidden", !matches)
      visibleRows += matches ? 1 : 0
    })

    this.emptyTarget.classList.toggle("hidden", visibleRows > 0)
  }
}
