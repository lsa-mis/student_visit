import { Controller } from "@hotwired/stimulus"

// Restricts date selection to program-held dates by using a date dropdown + time input
// and syncing their values into a hidden datetime field for submission.
export default class extends Controller {
  static targets = ["hidden", "dateSelect", "timeInput"]
  static values = { initial: String }

  connect() {
    if (this.hasInitialValue && this.initialValue) {
      const dt = this.initialValue.trim()
      if (dt.length >= 16) {
        this.dateSelectTarget.value = dt.slice(0, 10)
        this.timeInputTarget.value = dt.slice(11, 16)
      }
    } else if (this.hasDateSelectTarget && this.dateSelectTarget.options.length > 0) {
      this.dateSelectTarget.selectedIndex = 0
      if (!this.timeInputTarget.value) this.timeInputTarget.value = "09:00"
    }
    this.syncToHidden()
    this.dateSelectTarget.addEventListener("change", this.syncToHidden.bind(this))
    this.timeInputTarget.addEventListener("change", this.syncToHidden.bind(this))
    this.timeInputTarget.addEventListener("input", this.syncToHidden.bind(this))
  }

  syncToHidden() {
    const date = this.dateSelectTarget.value
    const time = this.timeInputTarget.value || "09:00"
    this.hiddenTarget.value = date && time ? `${date}T${time}` : ""
  }
}
