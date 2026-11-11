// Make Action Text / Trix toolbar controls keyboard operable (LRA-1475).
// Trix ships toolbar buttons with tabindex="-1" and activates them on mousedown,
// so keyboard users cannot Tab to them or activate them with Enter/Space by default.

const TOOLBAR_BUTTON_SELECTOR =
  "button[data-trix-attribute], button[data-trix-action]"

function accessibleNameFor(button) {
  return button.getAttribute("aria-label") ||
    button.getAttribute("title") ||
    button.textContent.trim()
}

function syncPressedState(button) {
  // Toggle / attribute controls announce pressed state; pure actions do not.
  if (!button.hasAttribute("data-trix-attribute")) {
    button.removeAttribute("aria-pressed")
    return
  }

  const pressed =
    button.classList.contains("trix-active") ||
    button.hasAttribute("data-trix-active")
  button.setAttribute("aria-pressed", pressed ? "true" : "false")
}

function activateToolbarButton(button) {
  button.dispatchEvent(
    new MouseEvent("mousedown", {
      bubbles: true,
      cancelable: true,
      view: window
    })
  )
}

function enhanceButton(button) {
  if (button.dataset.trixA11yEnhanced === "true") return
  button.dataset.trixA11yEnhanced = "true"

  if (button.getAttribute("tabindex") === "-1") {
    button.removeAttribute("tabindex")
  }

  if (!button.getAttribute("aria-label")) {
    const name = accessibleNameFor(button)
    if (name) button.setAttribute("aria-label", name)
  }

  syncPressedState(button)

  button.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return
    if (button.disabled) return

    // Match mouse activation: Trix listens for mousedown on toolbar controls.
    event.preventDefault()
    activateToolbarButton(button)
  })
}

function enhanceToolbar(toolbar) {
  if (!toolbar) return

  toolbar.querySelectorAll(TOOLBAR_BUTTON_SELECTOR).forEach(enhanceButton)

  if (toolbar.dataset.trixA11yObserver === "true") return
  toolbar.dataset.trixA11yObserver = "true"

  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      const target = mutation.target
      if (
        target.nodeType === Node.ELEMENT_NODE &&
        target.matches(TOOLBAR_BUTTON_SELECTOR)
      ) {
        syncPressedState(target)
      }
    }
  })

  observer.observe(toolbar, {
    attributes: true,
    subtree: true,
    attributeFilter: ["class", "data-trix-active"]
  })
}

function enhanceAllToolbars() {
  document.querySelectorAll("trix-toolbar").forEach(enhanceToolbar)
}

document.addEventListener("trix-initialize", (event) => {
  enhanceToolbar(event.target.toolbarElement)
})

document.addEventListener("turbo:load", enhanceAllToolbars)
document.addEventListener("DOMContentLoaded", enhanceAllToolbars)

if (document.readyState !== "loading") {
  enhanceAllToolbars()
}
