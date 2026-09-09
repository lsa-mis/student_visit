# frozen_string_literal: true

# Rails filtered_path redacts query-string keys, not path-segment secrets.
# Password reset tokens live at /passwords/:token and would otherwise be sent
# to Sentry Logs (and error request URLs) in production/staging.
class SentrySensitivePathFilter
  FILTERED = "[FILTERED]"
  PASSWORD_RESET_TOKEN = %r{/passwords/(?!new(?:[/?#]|\z))([^/?#]+)}i

  def self.redact(value)
    return value unless value.is_a?(String)

    value.gsub(PASSWORD_RESET_TOKEN, "/passwords/#{FILTERED}")
  end

  def self.apply_to_log(log)
    return log unless log

    redact_hash_values!(log.attributes) if log.respond_to?(:attributes)
    log.body = redact(log.body) if log.respond_to?(:body=)
    log
  end

  def self.apply_to_event(event)
    return event unless event
    return event unless event.respond_to?(:request) && event.request

    request = event.request
    request.url = redact(request.url) if request.respond_to?(:url=)
    redact_hash_values!(request.headers)
    redact_hash_values!(request.data) if request.respond_to?(:data)
    event
  end

  def self.apply_to_breadcrumb(breadcrumb)
    return breadcrumb unless breadcrumb

    breadcrumb.message = redact(breadcrumb.message) if breadcrumb.respond_to?(:message=)
    redact_hash_values!(breadcrumb.data) if breadcrumb.respond_to?(:data)
    breadcrumb
  end

  def self.redact_hash_values!(hash)
    return unless hash.is_a?(Hash)

    hash.each do |key, value|
      hash[key] = redact(value) if value.is_a?(String)
    end
  end
  private_class_method :redact_hash_values!
end
