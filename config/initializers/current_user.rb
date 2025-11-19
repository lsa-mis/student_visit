# Make current_user available to all controllers, including Rails internal controllers
# This is needed for gems like lsa_tdx_feedback that call current_user on all controllers
ActionController::Base.class_eval do
  helper_method :current_user

  private

  def current_user
    # Use Current.user if available (set by ApplicationController)
    return Current.user if Current.user

    # For controllers that don't inherit from ApplicationController,
    # try to find the session manually
    return nil unless respond_to?(:cookies, true)

    begin
      session_id = cookies.signed[:session_id] if cookies.signed
      return nil unless session_id

      session = Session.find_by(id: session_id)
      session&.user
    rescue => e
      # If anything goes wrong (e.g., database not available), return nil
      Rails.logger.debug("Error in current_user: #{e.message}") if defined?(Rails.logger)
      nil
    end
  end
end
