# Google Maps API configuration
# Prefer ENV over credentials so tests don't require master key
env_key = ENV["GOOGLE_MAPS_API_KEY"].presence
Rails.application.config.google_maps_api_key = env_key || Rails.application.credentials.dig(:google_maps, :api_key)
