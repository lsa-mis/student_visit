class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    email_address = params[:email_address]
    password = params[:password]

    if user = User.authenticate_by(email_address: email_address, password: password)
      # Check if user is logging in with their UMID (initial password)
      # If so, require them to change their password
      if user.umid.present? && password == user.umid
        start_new_session_for user
        # Redirect to password reset page to force password change
        redirect_to edit_password_path(user.password_reset_token),
                    notice: "Please change your password before continuing."
      else
        start_new_session_for user
        redirect_to root_path
      end
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
