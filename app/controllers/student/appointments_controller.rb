class Student::AppointmentsController < ApplicationController
  before_action :set_program
  before_action :ensure_enrolled

  def index
    authorize :student_appointment, :index?
    @my_appointments = @program.appointments.for_student(current_user).upcoming.includes(:vip).order(:start_time)
    @available_appointments = @program.appointments.available.upcoming.includes(:vip).order(:start_time)
  end

  def available
    authorize :student_appointment, :index?
    @vips = @program.vips.ordered
    @selected_vip_id = params[:vip_id]

    scope = @program.appointments.available.upcoming.includes(:vip)
    scope = scope.for_vip(@program.vips.find(@selected_vip_id)) if @selected_vip_id.present?
    @appointments = scope.order(:start_time)
  end

  def my_appointments
    authorize :student_appointment, :index?
    @appointments = @program.appointments.for_student(current_user).includes(:vip).order(:start_time)
  end

  def select
    authorize :student_appointment, :create?

    appointment = @program.appointments.find(params[:id])

    if appointment.available?
      if appointment.select_by!(current_user)
        AppointmentsMailer.change_notification(current_user, appointment, "selected").deliver_later
        redirect_to available_student_department_program_appointments_path(@program.department, @program),
                    notice: "Appointment selected successfully."
      else
        redirect_to available_student_department_program_appointments_path(@program.department, @program),
                    alert: "Failed to select appointment."
      end
    else
      redirect_to available_student_department_program_appointments_path(@program.department, @program),
                  alert: "This appointment is no longer available."
    end
  end

  def delete
    authorize :student_appointment, :destroy?

    appointment = @program.appointments.for_student(current_user).find(params[:id])

    if appointment.release!
      AppointmentsMailer.change_notification(current_user, appointment, "deleted").deliver_later
      redirect_to my_appointments_student_department_program_appointments_path(@program.department, @program),
                  notice: "Appointment cancelled successfully."
    else
      redirect_to my_appointments_student_department_program_appointments_path(@program.department, @program),
                  alert: "Failed to cancel appointment."
    end
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def ensure_enrolled
    unless current_user.enrolled_in_program?(@program)
      redirect_to student_dashboard_path, alert: "You are not enrolled in this program."
    end
  end

  def current_user
    Current.user
  end
end
