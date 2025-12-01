class AppointmentsController < ApplicationController
  before_action :set_program
  before_action :set_appointment, only: [ :show ]

  def index
    @appointments = @program.appointments.includes(:vip, :student).order(:start_time)
    authorize Appointment.new(program: @program)
  end

  def show
    authorize @appointment
  end

  def bulk_upload
    authorize Appointment.new(program: @program), :create?
    @vips = @program.department.vips.ordered
  end

  def process_bulk_upload
    authorize Appointment.new(program: @program), :create?

    unless params[:file].present? && params[:vip_id].present?
      redirect_to bulk_upload_department_program_appointments_path(@program.department, @program), alert: "Please select a file and VIP."
      return
    end

    vip = @program.department.vips.find(params[:vip_id])
    service = BulkAppointmentUploadService.new(@program, vip, params[:file])
    if service.call
      flash[:notice] = "Successfully uploaded #{service.success_count} appointment(s)."
      flash[:alert] = "#{service.failure_count} failed." if service.failure_count > 0
      flash[:errors] = service.errors if service.errors.any?
    else
      flash[:alert] = "Upload failed: #{service.errors.join(', ')}"
    end

    redirect_to department_program_appointments_path(@program.department, @program)
  end

  def by_faculty
    authorize Appointment.new(program: @program), :index?
    @vip = @program.department.vips.find(params[:vip_id])
    @appointments = @program.appointments.for_vip(@vip).includes(:student).order(:start_time)
  end

  def by_student
    authorize Appointment.new(program: @program), :index?
    @student = User.find(params[:student_id])
    @appointments = @program.appointments.for_student(@student).includes(:vip).order(:start_time)
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_appointment
    @appointment = @program.appointments.find(params[:id])
  end
end
