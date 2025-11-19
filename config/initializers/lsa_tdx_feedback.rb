# Configure lsa_tdx_feedback gem to allow unauthenticated access
# Feedback forms should be accessible without authentication
Rails.application.config.to_prepare do
  if defined?(LsaTdxFeedback::FeedbackController)
    LsaTdxFeedback::FeedbackController.class_eval do
      # Skip authentication for feedback submissions
      # Use raise: false to prevent errors if the before_action doesn't exist
      skip_before_action :require_authentication, raise: false
    end
  end
rescue => e
  Rails.logger.warn("Could not configure LsaTdxFeedback: #{e.message}") if defined?(Rails.logger)
end
