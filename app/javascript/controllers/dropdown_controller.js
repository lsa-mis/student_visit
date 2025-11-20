import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeMenu = this.closeMenu.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains("hidden")) {
      this.openMenu()
    } else {
      this.closeMenu()
    }
  }

  openMenu() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.closeMenu)
  }

  closeMenu(event) {
    if (event && this.element.contains(event.target)) {
      return
    }
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeMenu)
  }

  disconnect() {
    document.removeEventListener("click", this.closeMenu)
  }
}
