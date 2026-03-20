import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()

    const uniqueId = Date.now().toString()
    const content = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uniqueId)
    this.listTarget.insertAdjacentHTML("beforeend", content)
  }
}
