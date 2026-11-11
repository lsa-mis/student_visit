import { Controller } from "@hotwired/stimulus"

// Toggles dashboard image alt text vs decorative checkbox on Edit Program Content.
export default class extends Controller {
  static targets = ["altInput", "decorativeCheckbox", "fileInput", "fields"]

  connect() {
    this.syncDecorativeState()
  }

  decorativeChanged() {
    this.syncDecorativeState()
  }

  altInputChanged() {
    if (this.altInputTarget.value.trim() !== "" && this.decorativeCheckboxTarget.checked) {
      this.decorativeCheckboxTarget.checked = false
      this.altInputTarget.disabled = false
    }
  }

  fileChanged() {
    // Keep fields visible; validation runs server-side when a new file is attached.
    this.syncDecorativeState()
  }

  syncDecorativeState() {
    const decorative = this.decorativeCheckboxTarget.checked
    this.altInputTarget.disabled = decorative
    if (decorative) {
      this.altInputTarget.value = ""
    }
  }
}
