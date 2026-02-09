import { Controller } from "@hotwired/stimulus"

// Syncs office number field with the selected VIP's office number.
// Attach via data-controller="vip-office-number" on a wrapper containing:
// - A select with data-vip-office-number-target="vipSelect" and data-vip-office-numbers (JSON map).
// - An input with data-vip-office-number-target="officeNumber".
// - Optional value initialVipId: when set (e.g. on edit), only auto-fills when the field
//   is empty or matches the initial VIP's office number, so user can keep a custom value.
// Wire the select with data-action="change->vip-office-number#onVipChange".
export default class extends Controller {
  static targets = ["vipSelect", "officeNumber"]
  static values = { initialVipId: String }

  onVipChange() {
    if (!this.hasVipSelectTarget || !this.hasOfficeNumberTarget) return
    const map = this.officeNumberMap()
    const selectedVipId = this.vipSelectTarget.value
    const newOffice = selectedVipId ? (map[selectedVipId] || "") : ""

    if (this.hasInitialVipIdValue) {
      const currentOffice = map[this.initialVipIdValue]
      const shouldUpdate =
        !this.officeNumberTarget.value ||
        (currentOffice && this.officeNumberTarget.value === currentOffice)
      if (shouldUpdate) this.officeNumberTarget.value = newOffice
    } else {
      this.officeNumberTarget.value = newOffice
    }
  }

  officeNumberMap() {
    try {
      return JSON.parse(this.vipSelectTarget.dataset.vipOfficeNumbers || "{}")
    } catch {
      return {}
    }
  }
}
