import { Controller } from "@hotwired/stimulus"

const DEFAULT_THEME = "ocean"
const STORAGE_KEY = "stockflow-theme"

export default class extends Controller {
  static targets = ["select"]

  connect() {
    const theme = this.savedTheme()
    this.applyTheme(theme)
  }

  change(event) {
    this.applyTheme(event.target.value)
  }

  applyTheme(themeName) {
    const theme = this.normalizeTheme(themeName)
    document.documentElement.setAttribute("data-theme", theme)
    this.persistTheme(theme)

    if (this.hasSelectTarget) {
      this.selectTarget.value = theme
    }
  }

  savedTheme() {
    try {
      return this.normalizeTheme(localStorage.getItem(STORAGE_KEY))
    } catch (_error) {
      return DEFAULT_THEME
    }
  }

  normalizeTheme(themeName) {
    return ["ocean", "forest", "classic"].includes(themeName) ? themeName : DEFAULT_THEME
  }

  persistTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch (_error) {
      // Ignore storage failures and keep in-memory theme.
    }
  }
}
