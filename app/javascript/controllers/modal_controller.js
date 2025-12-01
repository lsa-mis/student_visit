import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "content"]

  connect() {
    this.closeModal = this.closeModal.bind(this)
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.handleEscape.bind(this))
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.closeModal()
  }

  closeModal() {
    this.overlayTarget.classList.add("hidden")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.handleEscape.bind(this))
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.closeModal()
    }
  }

  clickOutside(event) {
    if (event.target === this.overlayTarget) {
      this.closeModal()
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleEscape.bind(this))
    document.body.style.overflow = ""
  }
}
