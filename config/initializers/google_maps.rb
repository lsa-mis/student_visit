# Google Maps API configuration
# Set GOOGLE_MAPS_API_KEY in your credentials or environment variables
Rails.application.config.google_maps_api_key = Rails.application.credentials.dig(:google_maps, :api_key) || ENV["GOOGLE_MAPS_API_KEY"]
