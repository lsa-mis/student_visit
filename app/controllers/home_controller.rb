class HomeController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  def index
    if authenticated?
      redirect_to_appropriate_dashboard
    else
      # Show login page or landing page for unauthenticated users
      # Render the view instead of redirecting to allow tests to verify content
    end
  end

  private

  def redirect_to_appropriate_dashboard
    user = Current.user

    if user&.super_admin?
      redirect_to departments_path
    elsif user&.department_admin?
      # Redirect to first department they admin, or departments list
      if user.administered_departments.any?
        redirect_to department_path(user.administered_departments.first)
      else
        redirect_to departments_path
      end
    elsif user&.student?
      redirect_to student_dashboard_path
    else
      # No role assigned, redirect to login
      redirect_to new_session_path
    end
  end
end
