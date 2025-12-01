import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions", "hiddenUserId"]
  static values = { searchUrl: String }

  connect() {
    this.closeSuggestions = this.closeSuggestions.bind(this)
    this.timeout = null
    document.addEventListener("click", this.closeSuggestions)
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.hideSuggestions()
      return
    }

    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      const users = await response.json()
      this.showSuggestions(users)
    } catch (error) {
      console.error("Search error:", error)
      this.hideSuggestions()
    }
  }

  showSuggestions(users) {
    if (users.length === 0) {
      this.hideSuggestions()
      return
    }

    this.suggestionsTarget.innerHTML = users.map(user => {
      const escapedEmail = this.escapeHtml(user.email_address)
      const escapedFirstName = user.first_name ? this.escapeHtml(user.first_name) : ''
      const escapedLastName = user.last_name ? this.escapeHtml(user.last_name) : ''
      const fullName = [user.first_name, user.last_name].filter(Boolean).join(' ')
      const escapedFullName = fullName ? this.escapeHtml(fullName) : ''

      return `
        <div class="px-4 py-2 hover:bg-gray-100 cursor-pointer border-b border-gray-200 last:border-b-0"
             data-action="click->email-autocomplete#selectUser"
             data-email-autocomplete-user-id-param="${user.id}"
             data-email-autocomplete-email-param="${escapedEmail}"
             data-email-autocomplete-last-name-param="${escapedLastName}"
             data-email-autocomplete-first-name-param="${escapedFirstName}"
             data-email-autocomplete-umid-param="${user.umid || ''}">
          <div class="font-medium text-gray-900">${escapedEmail}</div>
          ${fullName ? `<div class="text-sm text-gray-500">${escapedFullName}</div>` : ''}
        </div>
      `
    }).join('')
    this.suggestionsTarget.classList.remove("hidden")
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add("hidden")
    this.suggestionsTarget.innerHTML = ""
  }

  selectUser(event) {
    const userId = event.currentTarget.dataset.emailAutocompleteUserIdParam
    const email = event.currentTarget.dataset.emailAutocompleteEmailParam
    const lastName = event.currentTarget.dataset.emailAutocompleteLastNameParam
    const firstName = event.currentTarget.dataset.emailAutocompleteFirstNameParam
    const umid = event.currentTarget.dataset.emailAutocompleteUmidParam

    this.inputTarget.value = email
    if (this.hiddenUserIdTarget) {
      this.hiddenUserIdTarget.value = userId
    }

    // Populate other fields if they exist
    const lastNameField = this.element.querySelector('[name="last_name"]')
    const firstNameField = this.element.querySelector('[name="first_name"]')
    const umidField = this.element.querySelector('[name="umid"]')

    if (lastNameField && lastName) lastNameField.value = lastName
    if (firstNameField && firstName) firstNameField.value = firstName
    if (umidField && umid) umidField.value = umid

    this.hideSuggestions()
  }

  closeSuggestions(event) {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
    document.removeEventListener("click", this.closeSuggestions)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
