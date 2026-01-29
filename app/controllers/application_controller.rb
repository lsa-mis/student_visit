class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include SentryMetrics
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Skip in development so Responsive Design Mode (and other dev tools that change User-Agent) don't get 406.
  allow_browser versions: :modern unless Rails.env.development?
end
