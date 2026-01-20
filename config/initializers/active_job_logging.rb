# Track ActiveJob events for debugging
# This helps us see when jobs are queued, started, and completed/failed

ActiveSupport::Notifications.subscribe("enqueue.active_job") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  job = event.payload[:job]

  # Log mail delivery jobs specifically
  if job.class.name == "ActionMailer::MailDeliveryJob"
    mailer_class = job.arguments[0] rescue "Unknown"
    mailer_method = job.arguments[1] rescue "Unknown"
    Rails.logger.info("Email job queued: #{mailer_class}.#{mailer_method}")
  end
rescue StandardError => e
  Rails.logger.error("Error in ActiveJob enqueue handler: #{e.message}")
end

ActiveSupport::Notifications.subscribe("perform_start.active_job") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  job = event.payload[:job]

  # Log mail delivery jobs specifically
  if job.class.name == "ActionMailer::MailDeliveryJob"
    mailer_class = job.arguments[0] rescue "Unknown"
    mailer_method = job.arguments[1] rescue "Unknown"
    Rails.logger.info("Email job started: #{mailer_class}.#{mailer_method}")
  end
rescue StandardError => e
  Rails.logger.error("Error in ActiveJob perform_start handler: #{e.message}")
end

ActiveSupport::Notifications.subscribe("perform.active_job") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  job = event.payload[:job]
  exception = event.payload[:exception_object]

  # Log mail delivery jobs specifically
  if job.class.name == "ActionMailer::MailDeliveryJob"
    mailer_class = job.arguments[0] rescue "Unknown"
    mailer_method = job.arguments[1] rescue "Unknown"

    if exception
      # Log failures
      Rails.logger.error("Email job failed: #{mailer_class}.#{mailer_method}")
      Rails.logger.error("Error: #{exception.class}: #{exception.message}")
      Rails.logger.error(exception.backtrace&.first(5)&.join("\n"))
    else
      # Log successful completion
      Rails.logger.info("Email job completed successfully: #{mailer_class}.#{mailer_method}")
    end
  end
rescue StandardError => e
  Rails.logger.error("Error in ActiveJob notification handler: #{e.message}")
end
