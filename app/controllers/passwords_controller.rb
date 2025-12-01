class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation).merge(must_change_password: false))
      # Check if this is a first login password change (user is already authenticated)
      is_first_login = Current.user == @user

      # Only destroy sessions if this is a manual password reset (not first login)
      @user.sessions.destroy_all unless is_first_login

      # Redirect to appropriate destination
      if is_first_login && session[:return_to_after_password_change].present?
        destination = session.delete(:return_to_after_password_change)
        redirect_to destination, notice: "Password has been changed. Welcome!"
      elsif is_first_login
        # First login but no stored destination, go to student dashboard or root
        destination = @user.student? ? student_dashboard_path : root_path
        redirect_to destination, notice: "Password has been changed. Welcome!"
      else
        # Manual password reset
        redirect_to new_session_path, notice: "Password has been reset."
      end
    else
      redirect_to edit_password_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end
end
