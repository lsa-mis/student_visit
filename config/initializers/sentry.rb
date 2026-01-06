# frozen_string_literal: true

Sentry.init do |config|
  # Use credentials instead of ENV or hardcoded value
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)

  # Only enable in production and staging environments
  config.enabled_environments = %w[production staging]

  # Environment-specific configuration
  config.environment = Rails.env
  config.release = Rails.application.class.module_parent_name.underscore.dasherize

  # Logging configuration
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Enable logging integration (this is the correct way for sentry-rails)
  # The sentry-rails gem automatically integrates with Rails logger
  # To send logs to Sentry, use: Sentry.capture_message("Your log message", level: :info)

  # Add user context data (PII) - be careful with this in production
  config.send_default_pii = Rails.env.development? || Rails.env.test?

  # Server name for better debugging
  config.server_name = Socket.gethostname

  # Performance monitoring
  # In production, you might want to lower this to something like 0.1 (10%)
  # depending on your traffic volume
  config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Profile sampling - adjust based on your needs
  config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Custom sampling logic if needed
  config.traces_sampler = lambda do |context|
    # Don't sample health check endpoints
    if context[:transaction_context][:name]&.include?("health_check")
      0.0
    else
      # Sample based on environment
      Rails.env.production? ? 0.1 : 1.0
    end
  end

  # Add additional context to errors
  config.before_send = lambda do |event, _hint|
    # Add request context
    if event.request
      event.request.data = {
        user_agent: event.request.headers["User-Agent"],
        referer: event.request.headers["Referer"],
        remote_addr: event.request.headers["X-Forwarded-For"] || event.request.headers["Remote-Addr"]
      }
    end

    # Add user context if available
    if defined?(Current) && Current.user
      event.user = {
        id: Current.user.id,
        email: Current.user.email,
        username: Current.user.try(:username)
      }
    end

    # Add custom tags
    event.tags = event.tags.merge(
      environment: Rails.env,
      version: Rails.application.class.module_parent_name.underscore.dasherize
    )

    # Filter out sensitive data
    if event.exception
      event.exception.values.each do |exception|
        next unless exception.value
        # Remove potential passwords, tokens, etc.
        exception.value.gsub!(/password[=:]\s*[^\s&]+/i, "password=[FILTERED]")
        exception.value.gsub!(/token[=:]\s*[^\s&]+/i, "token=[FILTERED]")
        exception.value.gsub!(/secret[=:]\s*[^\s&]+/i, "secret=[FILTERED]")
      end
    end

    event
  end

  # Configure backtrace cleanup
  config.backtrace_cleanup_callback = lambda do |backtrace|
    Rails.backtrace_cleaner.clean(backtrace)
  end

  # Configure error filtering
  config.before_send_transaction = lambda do |event, _hint|
    # Filter out health check transactions
    return nil if event.transaction&.include?("health_check")

    # Filter out static asset requests
    return nil if event.transaction&.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg)$/)

    event
  end

  # Configure breadcrumb filtering
  config.before_breadcrumb = lambda do |breadcrumb, _hint|
    # Filter out sensitive breadcrumbs
    return nil if breadcrumb.message&.match?(/password|token|secret/i)

    # Filter out noisy breadcrumbs
    return nil if breadcrumb.message&.match?(/SELECT.*FROM.*users/i)

    breadcrumb
  end

  # Configure sampling for different types of events
  config.sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Configure max breadcrumbs
  config.max_breadcrumbs = 50

  # Configure debug mode (only in development)
  config.debug = Rails.env.development?
end
