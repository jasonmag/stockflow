import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "reference"]

  connect() {
    this.sync()
  }

  sync() {
    const date = this.dateTarget.value
    this.referenceTarget.value = date ? `PO-${date}-1` : ""
  }
}
