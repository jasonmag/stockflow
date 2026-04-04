import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "@zxing/browser"

export default class extends Controller {
  static targets = ["input", "preview", "startButton", "stopButton", "status"]

  connect() {
    this.reader = new BrowserMultiFormatReader()
    this.readerControls = null
    this.scanning = false
    this.refocusInterval = null
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
      await this.startZxingScanner()
    } catch (error) {
      console.error("Barcode scanner start failed:", error)
      this.updateStatus("Unable to start camera. Check camera permissions.")
      this.stop()
    }
  }

  stop() {
    this.scanning = false
    if (this.refocusInterval) {
      clearInterval(this.refocusInterval)
      this.refocusInterval = null
    }
    if (this.readerControls) {
      this.readerControls.stop()
      this.readerControls = null
    }
    this.previewTarget.srcObject = null
    this.previewTarget.classList.add("hidden")
    this.startButtonTarget.classList.remove("hidden")
    this.stopButtonTarget.classList.add("hidden")
  }

  async startZxingScanner() {
    const deviceId = await this.findPreferredCameraId()
    this.readerControls = await this.reader.decodeFromVideoDevice(
      deviceId,
      this.previewTarget,
      (result, _error) => {
        if (!this.scanning || !result) return

        const value = result.getText()?.trim()
        if (value) {
          this.inputTarget.value = value
          this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
          this.updateStatus(`Barcode captured: ${value}`)
          this.stop()
        }
      }
    )
    this.applyTrackOptimizations()
    this.startRefocusLoop()
    this.updateStatus("Scanning... align barcode inside the camera frame.")
  }

  startRefocusLoop() {
    if (this.refocusInterval) clearInterval(this.refocusInterval)
    this.refocusInterval = setInterval(() => {
      this.triggerRefocus()
    }, 2500)
  }

  async triggerRefocus() {
    if (!this.scanning) return

    const stream = this.previewTarget.srcObject
    if (!stream) return
    const [track] = stream.getVideoTracks()
    if (!track || !track.getCapabilities || !track.applyConstraints) return

    const capabilities = track.getCapabilities()
    if (!capabilities.focusMode) return

    try {
      if (capabilities.focusMode.includes("single-shot")) {
        await track.applyConstraints({ advanced: [{ focusMode: "single-shot" }] })
      }
      if (capabilities.focusMode.includes("continuous")) {
        await track.applyConstraints({ advanced: [{ focusMode: "continuous" }] })
      }
    } catch (_error) {
      // Ignore unsupported focus constraints.
    }
  }

  async findPreferredCameraId() {
    try {
      const warmup = await navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      warmup.getTracks().forEach((track) => track.stop())
    } catch (_error) {
      // Ignore and continue with default device selection.
    }

    const devices = await navigator.mediaDevices.enumerateDevices()
    const videoInputs = devices.filter((d) => d.kind === "videoinput")
    if (videoInputs.length === 0) return null

    const rear =
      videoInputs.find((d) => /back|rear|environment/i.test(d.label)) ||
      videoInputs[videoInputs.length - 1]

    return rear.deviceId || null
  }

  async applyTrackOptimizations() {
    const stream = this.previewTarget.srcObject
    if (!stream) return
    const [track] = stream.getVideoTracks()
    if (!track) return

    const capabilities = track.getCapabilities ? track.getCapabilities() : {}
    const advanced = []

    if (capabilities.focusMode && capabilities.focusMode.includes("continuous")) {
      advanced.push({ focusMode: "continuous" })
    }
    if (capabilities.zoom && typeof capabilities.zoom.max === "number") {
      const midZoom = Math.min(Math.max(1, capabilities.zoom.min || 1), capabilities.zoom.max)
      advanced.push({ zoom: midZoom })
    }
    if (capabilities.torch) {
      advanced.push({ torch: false })
    }

    if (advanced.length === 0) return
    try {
      await track.applyConstraints({ advanced })
    } catch (_error) {
      // Best-effort only; keep scanning even if constraints are unsupported.
    }
  }

  updateStatus(message) {
    this.statusTarget.textContent = message
  }
}
