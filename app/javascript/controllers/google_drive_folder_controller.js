import { Controller } from "@hotwired/stimulus"

const GOOGLE_DRIVE_FOLDER_URL_PATTERN = /^https:\/\/drive\.google\.com\/drive(?:\/u\/\d+)?\/folders\/([^/?#]+)/i

export default class extends Controller {
  static targets = ["input", "preview", "submit", "edit", "cancel"]

  connect() {
    this.originalValue = this.inputTarget.value
    this.setEditing(false)
    this.updatePreview()
  }

  submit() {
    this.inputTarget.value = this.normalizeValue(this.inputTarget.value)
    this.originalValue = this.inputTarget.value
    this.setEditing(false)
    this.updatePreview()
  }

  preview() {
    this.updatePreview()
  }

  edit() {
    this.setEditing(true)
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    this.inputTarget.value = this.originalValue
    this.setEditing(false)
    this.updatePreview()
  }

  normalizeValue(value) {
    const trimmedValue = value.trim()
    const match = trimmedValue.match(GOOGLE_DRIVE_FOLDER_URL_PATTERN)
    return match ? match[1] : trimmedValue
  }

  setEditing(isEditing) {
    this.inputTarget.readOnly = !isEditing
    this.inputTarget.classList.toggle("bg-slate-100", !isEditing)
    this.inputTarget.classList.toggle("cursor-not-allowed", !isEditing)

    if (this.hasSubmitTarget) {
      this.submitTarget.classList.toggle("hidden", !isEditing)
    }

    if (this.hasCancelTarget) {
      this.cancelTarget.classList.toggle("hidden", !isEditing)
    }

    if (this.hasEditTarget) {
      this.editTarget.classList.toggle("hidden", isEditing)
    }
  }

  updatePreview() {
    if (!this.hasPreviewTarget) return

    const normalizedValue = this.normalizeValue(this.inputTarget.value)
    this.previewTarget.textContent = normalizedValue.length > 0 ? normalizedValue : "root"
  }
}
