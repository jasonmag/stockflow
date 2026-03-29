import { Controller } from "@hotwired/stimulus"

const MOBILE_MEDIA_QUERY = "(max-width: 767px)"
const MOBILE_USER_AGENT_PATTERN = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i

export default class extends Controller {
  static targets = ["panel", "toggle"]

  connect() {
    this.open = false
    this.mediaQuery = window.matchMedia(MOBILE_MEDIA_QUERY)
    this.handleMediaChange = () => this.sync()
    this.mediaQuery.addEventListener("change", this.handleMediaChange)
    this.sync()
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.handleMediaChange)
  }

  toggle() {
    if (!this.isMobile()) return

    this.open = !this.open
    this.render()
  }

  sync() {
    if (!this.isMobile()) {
      this.open = true
    }

    document.documentElement.dataset.device = this.isMobile() ? "mobile" : "desktop"
    this.render()
  }

  isMobile() {
    return this.mediaQuery.matches || MOBILE_USER_AGENT_PATTERN.test(window.navigator.userAgent)
  }

  render() {
    if (this.hasPanelTarget) {
      this.panelTarget.hidden = this.isMobile() && !this.open
    }

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", this.open ? "true" : "false")
    }
  }
}
