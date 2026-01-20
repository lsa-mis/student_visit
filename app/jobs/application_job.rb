class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Log errors for mail delivery jobs so we can see when emails fail
  rescue_from StandardError, with: :handle_job_error

  private

    def handle_job_error(error)
      # Log the error with context
      Rails.logger.error("Job failed: #{self.class.name}")
      Rails.logger.error("Error: #{error.class.name}: #{error.message}")
      Rails.logger.error(error.backtrace.join("\n"))

      # Report to Sentry if available
      if defined?(Sentry) && Sentry.initialized?
        Sentry.capture_exception(error, extra: {
          job_class: self.class.name,
          arguments: arguments
        })
      end

      # Re-raise to let SolidQueue handle it (it will record it in failed_executions)
      raise
    end
end
