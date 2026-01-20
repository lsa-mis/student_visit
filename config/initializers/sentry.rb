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

  # Metrics configuration
  # Enable metrics collection (if supported by your Sentry version)
  # Note: Metrics API may be deprecated in newer versions, but the methods still work
  if config.respond_to?(:enable_metrics)
    config.enable_metrics = true
  elsif config.respond_to?(:metrics) && config.metrics.respond_to?(:enabled=)
    config.metrics.enabled = true
  end

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

# Automatic request metrics tracking
# This will track HTTP request duration, status codes, and other request-level metrics
ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  next unless defined?(Sentry) && Sentry.initialized?
  next unless Sentry.configuration.enabled_environments.include?(Rails.env)
  next unless defined?(Sentry::Metrics) && Sentry::Metrics.respond_to?(:distribution)

  controller = event.payload[:controller]
  action = event.payload[:action]
  status = event.payload[:status]
  format = event.payload[:format] || "html"
  method = event.payload[:method] || "GET"
  duration_ms = event.duration

  # Track request duration
  Sentry::Metrics.distribution(
    "http.request.duration",
    duration_ms,
    unit: "millisecond",
    attributes: {
      controller: controller,
      action: action,
      status: status.to_s,
      format: format,
      method: method,
      environment: Rails.env
    }
  )

  # Track request count by status code
  Sentry::Metrics.count(
    "http.request.count",
    value: 1,
    attributes: {
      controller: controller,
      action: action,
      status: status.to_s,
      format: format,
      method: method,
      status_category: status.to_s[0] + "xx", # e.g., "2xx", "4xx", "5xx"
      environment: Rails.env
    }
  )

  # Track slow requests (> 1 second)
  if duration_ms > 1000
    Sentry::Metrics.count(
      "http.request.slow",
      value: 1,
      attributes: {
        controller: controller,
        action: action,
        status: status.to_s,
        method: method,
        environment: Rails.env
      }
    )
  end

  # Track error responses (4xx and 5xx)
  if status >= 400
    Sentry::Metrics.count(
      "http.request.error",
      value: 1,
      attributes: {
        controller: controller,
        action: action,
        status: status.to_s,
        method: method,
        error_type: status >= 500 ? "server_error" : "client_error",
        environment: Rails.env
      }
    )
  end
rescue StandardError => e
  Rails.logger.error("Failed to track request metrics: #{e.message}")
end

# Track database query metrics
ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  next unless defined?(Sentry) && Sentry.initialized?
  next unless Sentry.configuration.enabled_environments.include?(Rails.env)
  next unless defined?(Sentry::Metrics) && Sentry::Metrics.respond_to?(:distribution)

  name = event.payload[:name]
  sql = event.payload[:sql]
  duration_ms = event.duration

  # Extract query type (SELECT, INSERT, UPDATE, DELETE)
  query_type = sql&.strip&.upcase&.split&.first || "UNKNOWN"

  # Track query duration
  Sentry::Metrics.distribution(
    "db.query.duration",
    duration_ms,
    unit: "millisecond",
    attributes: {
      query_type: query_type,
      name: name,
      environment: Rails.env
    }
  )

  # Track slow queries (> 100ms)
  if duration_ms > 100
    Sentry::Metrics.count(
      "db.query.slow",
      value: 1,
      attributes: {
        query_type: query_type,
        name: name,
        environment: Rails.env
      }
    )
  end
rescue StandardError => e
  Rails.logger.error("Failed to track database metrics: #{e.message}")
end

# Track view rendering metrics
ActiveSupport::Notifications.subscribe("render_template.action_view") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  next unless defined?(Sentry) && Sentry.initialized?
  next unless Sentry.configuration.enabled_environments.include?(Rails.env)
  next unless defined?(Sentry::Metrics) && Sentry::Metrics.respond_to?(:distribution)

  identifier = event.payload[:identifier]
  duration_ms = event.duration

  # Extract template name
  template_name = identifier&.split("/")&.last&.split(".")&.first || "unknown"

  Sentry::Metrics.distribution(
    "view.render.duration",
    duration_ms,
    unit: "millisecond",
    attributes: {
      template: template_name,
      environment: Rails.env
    }
  )
rescue StandardError => e
  Rails.logger.error("Failed to track view metrics: #{e.message}")
end
