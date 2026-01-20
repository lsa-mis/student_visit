# frozen_string_literal: true

# Concern for tracking Sentry metrics throughout the application
module SentryMetrics
  extend ActiveSupport::Concern

  private

  # Track a counter metric
  # @param name [String] Metric name
  # @param value [Numeric] Counter increment value (default: 1)
  # @param attributes [Hash] Additional attributes/tags
  def track_counter(name, value: 1, **attributes)
    return unless sentry_enabled?

    Sentry::Metrics.count(name, value: value, attributes: normalize_attributes(attributes))
  rescue StandardError => e
    Rails.logger.error("Failed to track counter metric: #{e.message}")
  end

  # Track a gauge metric
  # @param name [String] Metric name
  # @param value [Numeric] Gauge value
  # @param unit [String] Unit of measurement (e.g., 'millisecond', 'byte')
  # @param attributes [Hash] Additional attributes/tags
  def track_gauge(name, value, unit: nil, **attributes)
    return unless sentry_enabled?

    options = { attributes: normalize_attributes(attributes) }
    options[:unit] = unit if unit
    Sentry::Metrics.gauge(name, value, **options)
  rescue StandardError => e
    Rails.logger.error("Failed to track gauge metric: #{e.message}")
  end

  # Track a distribution metric
  # @param name [String] Metric name
  # @param value [Numeric] Distribution value
  # @param unit [String] Unit of measurement (e.g., 'millisecond', 'kilobyte')
  # @param attributes [Hash] Additional attributes/tags
  def track_distribution(name, value, unit: nil, **attributes)
    return unless sentry_enabled?

    options = { attributes: normalize_attributes(attributes) }
    options[:unit] = unit if unit
    Sentry::Metrics.distribution(name, value, **options)
  rescue StandardError => e
    Rails.logger.error("Failed to track distribution metric: #{e.message}")
  end

  # Track request duration
  def track_request_duration(duration_ms, **attributes)
    track_distribution(
      "http.request.duration",
      duration_ms,
      unit: "millisecond",
      **attributes
    )
  end

  # Track database query duration
  def track_db_query_duration(duration_ms, query_type: nil, **attributes)
    attrs = attributes.dup
    attrs[:query_type] = query_type if query_type
    track_distribution(
      "db.query.duration",
      duration_ms,
      unit: "millisecond",
      **attrs
    )
  end

  # Track authentication events
  def track_auth_event(event_type, success: true, **attributes)
    track_counter(
      "auth.#{event_type}",
      value: 1,
      success: success.to_s,
      **attributes
    )
  end

  # Track business events (appointments, questionnaires, etc.)
  def track_business_event(event_type, **attributes)
    track_counter(
      "business.#{event_type}",
      value: 1,
      **attributes
    )
  end

  # Normalize attributes to ensure they're strings and safe
  def normalize_attributes(attributes)
    attributes.transform_keys(&:to_s).transform_values do |v|
      case v
      when Symbol
        v.to_s
      when true, false
        v.to_s
      when nil
        "nil"
      else
        v.to_s
      end
    end
  end

  # Check if Sentry is enabled and metrics API is available
  def sentry_enabled?
    return false unless defined?(Sentry)
    return false unless Sentry.initialized?
    return false unless Sentry.configuration.enabled_environments.include?(Rails.env)
    return false unless defined?(Sentry::Metrics)
    return false unless Sentry::Metrics.respond_to?(:count)
    true
  end
end
