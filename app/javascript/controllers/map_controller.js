import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    apiKey: String,
    address: String,
    customUrl: String
  }

  connect() {
    this.loadGoogleMaps()
  }

  loadGoogleMaps() {
    if (window.google && window.google.maps) {
      this.initMap()
      return
    }

    const script = document.createElement("script")
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&callback=initMapCallback`
    script.async = true
    script.defer = true

    window.initMapCallback = () => this.initMap()
    document.head.appendChild(script)
  }

  initMap() {
    const mapElement = this.element

    if (this.customUrlValue && this.customUrlValue.trim() !== "") {
      // Use custom Google Maps URL (embed)
      mapElement.innerHTML = `<iframe width="100%" height="100%" frameborder="0" style="border:0" src="${this.customUrlValue}" allowfullscreen></iframe>`
      return
    }

    // Default: Street view of department address
    if (!this.addressValue || this.addressValue.trim() === "") {
      mapElement.innerHTML = "<p class='p-4 text-gray-500'>No address provided</p>"
      return
    }

    const geocoder = new google.maps.Geocoder()
    const map = new google.maps.Map(mapElement, {
      zoom: 15,
      center: { lat: 0, lng: 0 }
    })

    geocoder.geocode({ address: this.addressValue }, (results, status) => {
      if (status === "OK" && results[0]) {
        const location = results[0].geometry.location

        // Create street view
        const panorama = new google.maps.StreetViewPanorama(mapElement, {
          position: location,
          pov: { heading: 270, pitch: 0 },
          zoom: 1
        })

        map.setStreetView(panorama)
      } else {
        mapElement.innerHTML = `<p class='p-4 text-red-500'>Error loading map: ${status}</p>`
      }
    })
  }
}
