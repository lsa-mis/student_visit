class Student::DashboardController < ApplicationController
  def show
    authorize [:student, :dashboard], :show?

    @enrolled_departments = current_user.enrolled_departments
    @selected_department_id = session[:selected_department_id]

    if @enrolled_departments.count == 1 && @selected_department_id.nil?
      @selected_department_id = @enrolled_departments.first.id
      session[:selected_department_id] = @selected_department_id
    end

    if @selected_department_id
      @selected_department = @enrolled_departments.find_by(id: @selected_department_id)
      @active_program = @selected_department&.active_program
      @vips = @active_program&.vips&.for_student_dashboard&.ordered || []
      @important_links = @active_program&.important_links&.ordered || []
    end
  end

  def preview
    authorize [:student, :dashboard], :preview?

    @selected_department = Department.find(params[:department_id])
    @active_program = @selected_department.programs.find(params[:program_id])

    unless Current.user&.department_admin_for?(@selected_department)
      raise Pundit::NotAuthorizedError
    end

    # Set session variables to indicate preview mode
    session[:preview_mode] = true
    session[:preview_department_id] = @selected_department.id
    session[:preview_program_id] = @active_program.id

    @enrolled_departments = [ @selected_department ]
    @selected_department_id = @selected_department.id
    @vips = @active_program.vips.for_student_dashboard.ordered
    @important_links = @active_program.important_links.ordered
    @preview_mode = true

    render :show
  end

  def select_department
    authorize [:student, :dashboard], :show?

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
