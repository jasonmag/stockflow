import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "@zxing/browser"

export default class extends Controller {
  static targets = ["input", "preview", "startButton", "stopButton", "status"]

  connect() {
    this.stream = null
    this.detector = null
    this.reader = new BrowserMultiFormatReader()
    this.readerControls = null
    this.scanning = false
  }

  disconnect() {
    this.stop()
  }

  async start() {
    if (!("mediaDevices" in navigator) || !("getUserMedia" in navigator.mediaDevices)) {
      this.updateStatus("Camera access is not available on this device.")
      return
    }

    try {
      this.previewTarget.classList.remove("hidden")
      this.startButtonTarget.classList.add("hidden")
      this.stopButtonTarget.classList.remove("hidden")
      this.scanning = true
      this.updateStatus("Starting camera scan...")

      if ("BarcodeDetector" in window) {
        await this.startNativeScanner()
      } else {
        await this.startZxingScanner()
      }
    } catch (_error) {
      this.updateStatus("Unable to start camera. Check camera permissions.")
      this.stop()
    }
  }

  stop() {
    this.scanning = false
    if (this.readerControls) {
      this.readerControls.stop()
      this.readerControls = null
    }
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop())
      this.stream = null
    }
    this.previewTarget.srcObject = null
    this.previewTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
    this.stopButtonTarget.classList.add("hidden")
  }

  async startNativeScanner() {
    this.detector = new window.BarcodeDetector({
      formats: ["ean_13", "ean_8", "upc_a", "upc_e", "code_128", "code_39", "itf", "qr_code"]
    })
    this.stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: "environment" } },
      audio: false
    })
    this.previewTarget.srcObject = this.stream
    this.updateStatus("Scanning with native detector...")
    this.scanLoop()
  }

  async startZxingScanner() {
    this.readerControls = await this.reader.decodeFromConstraints(
      { video: { facingMode: { ideal: "environment" } } },
      this.previewTarget,
      (result, _error) => {
        if (!this.scanning || !result) return

        const value = result.getText()
        if (value) {
          this.inputTarget.value = value
          this.updateStatus(`Barcode captured: ${value}`)
          this.stop()
        }
      }
    )
    this.updateStatus("Scanning with cross-browser detector...")
  }

  async scanLoop() {
    if (!this.scanning || !this.detector || !this.previewTarget.videoWidth) {
      if (this.scanning) requestAnimationFrame(() => this.scanLoop())
      return
    }

    try {
      const codes = await this.detector.detect(this.previewTarget)
      if (codes.length > 0) {
        const rawValue = codes[0].rawValue
        if (rawValue) {
          this.inputTarget.value = rawValue
          this.updateStatus(`Barcode captured: ${rawValue}`)
          this.stop()
          return
        }
      }
    } catch (_error) {
      this.updateStatus("Scanning failed. Try again.")
    }

    if (this.scanning) requestAnimationFrame(() => this.scanLoop())
  }

  updateStatus(message) {
    this.statusTarget.textContent = message
  }
}
