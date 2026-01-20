class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    email_address = params[:email_address]
    password = params[:password]

    # Validate required parameters before calling authenticate_by
    raise ArgumentError, "finder arguments are required" if email_address.blank?
    raise ArgumentError, "password arguments are required" if password.blank?

    if user = User.authenticate_by(email_address: email_address, password: password)
      # Check if user is logging in with their UMID (initial password) or must change password
      # If so, require them to change their password
      if user.must_change_password? || (user.umid.present? && password == user.umid)
        start_new_session_for user
        # Store intended destination for after password change
        intended_destination = session[:return_to_after_authenticating] || (user.student? ? student_dashboard_path : root_path)
        session[:return_to_after_password_change] = intended_destination
        # Track authentication success with password change required
        track_auth_event("login", success: true, requires_password_change: "true", user_role: user.roles.pluck(:name).join(","))
        # Redirect to password reset page to force password change
        redirect_to edit_password_path(user.password_reset_token),
                    notice: "Please change your password before continuing."
      else
        start_new_session_for user
        track_auth_event("login", success: true, requires_password_change: "false", user_role: user.roles.pluck(:name).join(","))
        redirect_to after_authentication_url
      end
    else
      track_auth_event("login", success: false, reason: "invalid_credentials")
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    user_role = Current.user&.roles&.pluck(:name)&.join(",") || "unknown"
    terminate_session
    track_auth_event("logout", success: true, user_role: user_role)
    redirect_to new_session_path, status: :see_other
  end
end
