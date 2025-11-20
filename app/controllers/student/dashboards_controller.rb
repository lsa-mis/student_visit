class Student::DashboardsController < ApplicationController
  def show
    authorize :student_dashboard, :show?

    @enrolled_departments = current_user.enrolled_departments
    @selected_department_id = session[:selected_department_id]

    if @enrolled_departments.count == 1 && @selected_department_id.nil?
      @selected_department_id = @enrolled_departments.first.id
      session[:selected_department_id] = @selected_department_id
    end

    if @selected_department_id
      @selected_department = @enrolled_departments.find_by(id: @selected_department_id)
      @active_program = @selected_department&.active_program
    end
  end

  def select_department
    authorize :student_dashboard, :show?

    department = current_user.enrolled_departments.find_by(id: params[:department_id])
    if department
      session[:selected_department_id] = department.id
      redirect_to student_dashboard_path, notice: "Department selected."
    else
      redirect_to student_dashboard_path, alert: "Invalid department."
    end
  end

  private

  def current_user
    Current.user
  end
end
