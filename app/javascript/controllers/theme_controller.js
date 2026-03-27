import { Controller } from "@hotwired/stimulus"

const DEFAULT_THEME = "light"
const STORAGE_KEY = "stockflow-theme"
const VALID_THEMES = ["light", "dark"]
const LEGACY_LIGHT_THEMES = ["ocean", "forest", "classic"]

export default class extends Controller {
  static targets = ["option"]

  connect() {
    const theme = this.savedTheme()
    this.applyTheme(theme)
  }

  set(event) {
    this.applyTheme(event.currentTarget.dataset.themeValue)
  }

  applyTheme(themeName) {
    const theme = this.normalizeTheme(themeName)
    document.documentElement.setAttribute("data-theme", theme)
    this.persistTheme(theme)

    this.syncOptions(theme)
  }

  savedTheme() {
    try {
      return this.normalizeTheme(localStorage.getItem(STORAGE_KEY))
    } catch (_error) {
      return DEFAULT_THEME
    }
  }

  normalizeTheme(themeName) {
    if (LEGACY_LIGHT_THEMES.includes(themeName)) return DEFAULT_THEME

    return VALID_THEMES.includes(themeName) ? themeName : DEFAULT_THEME
  }

  persistTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch (_error) {
      // Ignore storage failures and keep in-memory theme.
    }
  }

  syncOptions(activeTheme) {
    this.optionTargets.forEach((option) => {
      const isActive = option.dataset.themeValue === activeTheme

      option.setAttribute("aria-pressed", String(isActive))
      option.classList.toggle("theme-toggle-option-active", isActive)
    })
  }
}
