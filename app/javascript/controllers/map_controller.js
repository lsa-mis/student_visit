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
      // Check if it's already an embed URL
      if (this.customUrlValue.includes('/maps/embed')) {
        mapElement.innerHTML = `<iframe width="100%" height="100%" frameborder="0" style="border:0" src="${this.customUrlValue}" allowfullscreen></iframe>`
        return
      }

      // Extract coordinates from Google Maps share URL and use JavaScript API
      const coords = this.extractCoordinates(this.customUrlValue)
      if (coords) {
        // Use Google Maps JavaScript API (should be loaded by now)
        if (window.google && window.google.maps) {
          this.displayMapWithCoordinates(mapElement, coords)
        } else {
          // If API not loaded yet, wait a bit and try again
          setTimeout(() => {
            if (window.google && window.google.maps) {
              this.displayMapWithCoordinates(mapElement, coords)
            } else {
              mapElement.innerHTML = "<p class='p-4 text-red-500'>Error: Google Maps API failed to load</p>"
            }
          }, 500)
        }
        return
      }

      // If we can't parse it, try to use as embed URL (might work for some formats)
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

  extractCoordinates(url) {
    // Handle Google Maps share URLs with coordinates (@lat,lng,zoom)
    // Example: https://www.google.com/maps/@42.2782554,-83.7447896,17z
    const coordMatch = url.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*),(\d+)z/)
    if (coordMatch) {
      return {
        lat: parseFloat(coordMatch[1]),
        lng: parseFloat(coordMatch[2]),
        zoom: parseInt(coordMatch[3]) || 17
      }
    }

    // Handle place URLs with coordinates in query params
    try {
      const urlObj = new URL(url)
      const ll = urlObj.searchParams.get('ll')
      if (ll) {
        const [lat, lng] = ll.split(',')
        return {
          lat: parseFloat(lat),
          lng: parseFloat(lng),
          zoom: parseInt(urlObj.searchParams.get('z')) || 17
        }
      }
    } catch (e) {
      // Invalid URL, continue
    }

    return null
  }

  displayMapWithCoordinates(mapElement, coords) {
    try {
      // Use Google Maps JavaScript API to display the map
      const map = new google.maps.Map(mapElement, {
        zoom: coords.zoom || 17,
        center: { lat: coords.lat, lng: coords.lng },
        mapTypeId: 'roadmap'
      })

      // Add a marker at the location
      new google.maps.Marker({
        position: { lat: coords.lat, lng: coords.lng },
        map: map
      })
    } catch (error) {
      console.error('Error displaying map:', error)
      mapElement.innerHTML = `<p class='p-4 text-red-500'>Error displaying map: ${error.message}</p>`
    }
  }
}
