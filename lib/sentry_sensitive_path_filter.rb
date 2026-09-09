# frozen_string_literal: true

class SentrySensitivePathFilter
  FILTERED = "[FILTERED]"
  # Password reset tokens are route params (`/passwords/:token`), not query
  # params, so Rails filter_parameters and Sentry send_default_pii do not scrub them.
  PASSWORD_RESET_TOKEN_PATH = %r{/passwords/(?!new(?:[/?#]|\z))([^/?#]+)}

  def self.redact_path(value)
    return value unless value.is_a?(String)

    value.gsub(PASSWORD_RESET_TOKEN_PATH, "/passwords/#{FILTERED}")
  end

  def self.redact_log(log)
    return log if log.nil?

    attributes = log.respond_to?(:attributes) ? log.attributes : nil
    redact_hash!(attributes)
    log
  end

  def self.redact_event(event)
    return event if event.nil?

    redact_request!(event.request) if event.respond_to?(:request)
    event
  end

  def self.redact_breadcrumb(breadcrumb)
    return breadcrumb if breadcrumb.nil?

    if breadcrumb.respond_to?(:message=) && breadcrumb.message.is_a?(String)
      breadcrumb.message = redact_path(breadcrumb.message)
    end

    redact_hash!(breadcrumb.data) if breadcrumb.respond_to?(:data)
    breadcrumb
  end

  def self.redact_request!(request)
    return if request.nil?

    if request.is_a?(Hash)
      redact_hash!(request)
      return
    end

    %i[url path].each do |attr|
      setter = "#{attr}="
      next unless request.respond_to?(attr) && request.respond_to?(setter)

      value = request.public_send(attr)
      request.public_send(setter, redact_path(value)) if value.is_a?(String)
    end

    env = request.respond_to?(:env) ? request.env : nil
    return unless env.is_a?(Hash)

    %w[PATH_INFO REQUEST_URI].each do |key|
      env[key] = redact_path(env[key]) if env[key].is_a?(String)
    end
  end

  def self.redact_hash!(hash)
    return unless hash.is_a?(Hash)

    %i[path url].each do |key|
      hash[key] = redact_path(hash[key]) if hash[key].is_a?(String)
      hash[key.to_s] = redact_path(hash[key.to_s]) if hash[key.to_s].is_a?(String)
    end

    params = hash[:params] || hash["params"]
    redact_params!(params) if params.is_a?(Hash)
  end

  def self.redact_params!(params)
    %w[token password_reset_token].each do |key|
      params[key] = FILTERED if params.key?(key)
      params[key.to_sym] = FILTERED if params.key?(key.to_sym)
    end
  end

  private_class_method :redact_hash!, :redact_params!
end
