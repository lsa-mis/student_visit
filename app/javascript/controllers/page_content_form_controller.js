import { Controller } from "@hotwired/stimulus"

// Updates the area_name select when page_path changes.
// Expects area options JSON in a script[data-page-content-form-target="optionsData"].
// Shows an indicator when selected page_path + area_name already has content (existingData).
export default class extends Controller {
  static targets = ["pagePathSelect", "areaSelect", "optionsData", "existingData", "existingIndicator", "existingEditLink"]

  connect() {
    this.areaOptionsMap = this.optionsDataTarget ? JSON.parse(this.optionsDataTarget.textContent) : {}
    this.existingMap = this.hasExistingDataTarget ? JSON.parse(this.existingDataTarget.textContent) : {}
    this.syncAreas()
    this.checkExisting()
  }

  updateAreas() {
    this.syncAreas()
  }

  syncAreas() {
    const pathSelect = this.pagePathSelectTarget
    const areaSelect = this.areaSelectTarget
    const map = this.areaOptionsMap || {}

    const pagePath = pathSelect.value && pathSelect.value.trim()
    const options = map[pagePath] || []
    const currentValue = areaSelect.value

    areaSelect.innerHTML = ""
    const blank = document.createElement("option")
    blank.value = ""
    blank.textContent = options.length ? "Select an area..." : "Select a page first..."
    areaSelect.appendChild(blank)

    options.forEach(([ label, value ]) => {
      const opt = document.createElement("option")
      opt.value = value
      opt.textContent = label
      if (value === currentValue) opt.selected = true
      areaSelect.appendChild(opt)
    })

    if (!areaSelect.value && options.length === 1) {
      areaSelect.selectedIndex = 1
    }

    areaSelect.disabled = options.length === 0
    this.checkExisting()
  }

  checkExisting() {
    if (!this.hasExistingIndicatorTarget) return

    const pagePath = this.pagePathSelectTarget.value && this.pagePathSelectTarget.value.trim()
    const areaName = this.areaSelectTarget.value && this.areaSelectTarget.value.trim()
    const key = pagePath && areaName ? `${pagePath}|${areaName}` : null
    const editUrl = key && this.existingMap[key]

    if (editUrl) {
      this.existingIndicatorTarget.classList.remove("hidden")
      if (this.hasExistingEditLinkTarget) {
        this.existingEditLinkTarget.href = editUrl
      }
    } else {
      this.existingIndicatorTarget.classList.add("hidden")
    }
  }
}
