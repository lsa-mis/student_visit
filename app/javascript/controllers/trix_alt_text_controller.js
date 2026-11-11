import { Controller } from "@hotwired/stimulus"

// Prompts for alternative text (or decorative) when images are attached in Trix,
// and lets authors edit alt text later via double-click on an image attachment.
export default class extends Controller {
  static targets = ["dialog", "altInput", "decorativeCheckbox", "error"]

  connect() {
    this.pendingAttachment = null
    this.removingOnCancel = false
    this.boundAttachmentAdd = this.attachmentAdd.bind(this)
    this.boundAttachmentClick = this.attachmentClick.bind(this)
    this.boundDialogCancel = this.dialogCancel.bind(this)
    this.editor = this.element.querySelector("trix-editor")
    if (this.editor) {
      this.editor.addEventListener("trix-attachment-add", this.boundAttachmentAdd)
      this.editor.addEventListener("dblclick", this.boundAttachmentClick)
    }
    if (this.hasDialogTarget) {
      this.dialogTarget.addEventListener("cancel", this.boundDialogCancel)
    }
  }

  disconnect() {
    if (this.editor) {
      this.editor.removeEventListener("trix-attachment-add", this.boundAttachmentAdd)
      this.editor.removeEventListener("dblclick", this.boundAttachmentClick)
    }
    if (this.hasDialogTarget) {
      this.dialogTarget.removeEventListener("cancel", this.boundDialogCancel)
    }
  }

  attachmentAdd(event) {
    const attachment = event.attachment
    if (!attachment || !this.isImageAttachment(attachment)) return

    // Skip if alt was already set (re-hydrated from saved content).
    const existingAlt = attachment.getAttribute("alt")
    if (existingAlt !== undefined && existingAlt !== null) return

    this.openDialog(attachment, { removeOnCancel: true })
  }

  attachmentClick(event) {
    const figure = event.target.closest("figure[data-trix-attachment]")
    if (!figure || !this.editor?.editor) return

    const attachment = this.findSelectedAttachment()
    if (!attachment || !this.isImageAttachment(attachment)) return

    this.openDialog(attachment, { removeOnCancel: false })
  }

  openDialog(attachment, { removeOnCancel }) {
    this.pendingAttachment = attachment
    this.removingOnCancel = removeOnCancel

    const currentAlt = attachment.getAttribute("alt")
    const decorative = currentAlt === ""
    this.decorativeCheckboxTarget.checked = decorative
    this.altInputTarget.value = decorative || currentAlt == null ? "" : String(currentAlt)
    this.altInputTarget.disabled = decorative
    this.hideError()
    this.dialogTarget.showModal()
    this.altInputTarget.focus()
  }

  isImageAttachment(attachment) {
    const file = attachment.file
    if (file?.type?.startsWith("image/")) return true

    const contentType =
      attachment.getAttribute("contentType") ||
      attachment.attachment?.attributes?.values?.contentType ||
      ""
    return String(contentType).startsWith("image/")
  }

  findSelectedAttachment() {
    const piece = this.editor?.editor?.composition?.getSelectedAttachment?.()
    return piece || null
  }

  decorativeChanged() {
    const decorative = this.decorativeCheckboxTarget.checked
    this.altInputTarget.disabled = decorative
    if (decorative) {
      this.altInputTarget.value = ""
      this.hideError()
    }
  }

  altInputChanged() {
    if (this.altInputTarget.value.trim() !== "" && this.decorativeCheckboxTarget.checked) {
      this.decorativeCheckboxTarget.checked = false
      this.altInputTarget.disabled = false
    }
    if (this.altInputTarget.value.trim() !== "") this.hideError()
  }

  save(event) {
    event.preventDefault()
    if (!this.pendingAttachment) {
      this.dialogTarget.close()
      return
    }

    const decorative = this.decorativeCheckboxTarget.checked
    const alt = this.altInputTarget.value.trim()

    if (!decorative && alt === "") {
      this.showError()
      return
    }

    this.pendingAttachment.setAttributes({ alt: decorative ? "" : alt })
    this.pendingAttachment = null
    this.removingOnCancel = false
    this.dialogTarget.close()
  }

  cancel(event) {
    event.preventDefault()
    this.discardPendingAttachment()
    this.dialogTarget.close()
  }

  dialogCancel() {
    this.discardPendingAttachment()
  }

  discardPendingAttachment() {
    if (this.pendingAttachment && this.removingOnCancel) {
      this.pendingAttachment.remove()
    }
    this.pendingAttachment = null
    this.removingOnCancel = false
  }

  showError() {
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }
}
