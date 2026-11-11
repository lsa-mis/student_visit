# frozen_string_literal: true

# Allows booting the Rails app for CI tasks (e.g. importmap audit) when libvips
# is unavailable. GitHub-hosted runners periodically fail apt installs due to
# transient mirror/DNS issues; importmap audit does not need image processing.

module Kernel
  alias_method :__student_visit_original_require, :require

  def require(name)
    __student_visit_original_require(name)
  rescue LoadError => e
    raise unless e.message.include?("vips")

    warn "[ci] allowing boot without libvips: #{e.message}"
    false
  end
end
