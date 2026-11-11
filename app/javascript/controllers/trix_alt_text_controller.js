import { Controller } from "@hotwired/stimulus"

// Prompts for alternative text (or decorative) when images are attached in Trix,
// and lets authors edit alt text later via double-click or keyboard on a selected image.
export default class extends Controller {
  static targets = ["dialog", "altInput", "decorativeCheckbox", "error"]

  connect() {
    this.pendingAttachment = null
    this.pendingQueue = []
    this.removingOnCancel = false
    this.boundAttachmentAdd = this.attachmentAdd.bind(this)
    this.boundAttachmentClick = this.attachmentClick.bind(this)
    this.boundAttachmentKeydown = this.attachmentKeydown.bind(this)
    this.boundDialogCancel = this.dialogCancel.bind(this)
    this.editor = this.element.querySelector("trix-editor")
    if (this.editor) {
      this.editor.addEventListener("trix-attachment-add", this.boundAttachmentAdd)
      this.editor.addEventListener("dblclick", this.boundAttachmentClick)
      this.editor.addEventListener("keydown", this.boundAttachmentKeydown)
    }
    if (this.hasDialogTarget) {
      this.dialogTarget.addEventListener("cancel", this.boundDialogCancel)
    }
  }

  disconnect() {
    if (this.editor) {
      this.editor.removeEventListener("trix-attachment-add", this.boundAttachmentAdd)
      this.editor.removeEventListener("dblclick", this.boundAttachmentClick)
      this.editor.removeEventListener("keydown", this.boundAttachmentKeydown)
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

  // Keyboard-operable edit for a selected image attachment (Enter / Space).
  attachmentKeydown(event) {
    if (event.key !== "Enter" && event.key !== " ") return
    if (this.hasDialogTarget && this.dialogTarget.open) return

    const attachment = this.findSelectedAttachment()
    if (!attachment || !this.isImageAttachment(attachment)) return

    event.preventDefault()
    this.openDialog(attachment, { removeOnCancel: false })
  }

  openDialog(attachment, { removeOnCancel }) {
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.pendingQueue.push({ attachment, removeOnCancel })
      return
    }

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
    const composition = this.editor?.editor?.composition
    if (!composition) return null

    // Trix 2.1.x exposes getSelectedAttachments() (plural), not getSelectedAttachment().
    const selected = composition.getSelectedAttachments?.()
    if (Array.isArray(selected) && selected.length === 1) return selected[0]

    const fromDocument = this.editor?.editor?.getSelectedDocument?.()?.getAttachments?.()
    if (Array.isArray(fromDocument) && fromDocument.length === 1) return fromDocument[0]

    return null
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
      this.promptNextQueuedAttachment()
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
    this.promptNextQueuedAttachment()
  }

  cancel(event) {
    event.preventDefault()
    this.discardPendingAttachment()
    this.dialogTarget.close()
    this.promptNextQueuedAttachment()
  }

  dialogCancel() {
    this.discardPendingAttachment()
    this.promptNextQueuedAttachment()
  }

  discardPendingAttachment() {
    if (this.pendingAttachment && this.removingOnCancel) {
      this.pendingAttachment.remove()
    }
    this.pendingAttachment = null
    this.removingOnCancel = false
  }

  promptNextQueuedAttachment() {
    const next = this.pendingQueue.shift()
    if (!next) return
    // Defer so the previous dialog finishes closing before the next opens.
    queueMicrotask(() => this.openDialog(next.attachment, { removeOnCancel: next.removeOnCancel }))
  }

  showError() {
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }
}
