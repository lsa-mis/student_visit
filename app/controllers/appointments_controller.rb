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

  def new
    @appointment = @program.appointments.build
    authorize @appointment
    @vips = @program.vips.ordered
  end

  def create
    @appointment = @program.appointments.build(appointment_params)
    authorize @appointment
    @vips = @program.vips.ordered

    if @appointment.save
      redirect_to department_program_appointments_path(@program.department, @program), notice: "Appointment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def bulk_upload
    authorize Appointment.new(program: @program), :create?
    @vips = @program.vips.ordered
  end

  def process_bulk_upload
    authorize Appointment.new(program: @program), :create?

    unless params[:file].present? && params[:vip_id].present?
      redirect_to bulk_upload_department_program_appointments_path(@program.department, @program), alert: "Please select a file and VIP."
      return
    end

    vip = @program.vips.find(params[:vip_id])
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
    @vip = @program.vips.find(params[:vip_id])
    @appointments = @program.appointments.for_vip(@vip).includes(:student).order(:start_time)
  end

  def by_student
    authorize Appointment.new(program: @program), :index?
    @student = User.find(params[:student_id])
    @appointments = @program.appointments.for_student(@student).includes(:vip).order(:start_time)
  end

  def schedule_builder
    authorize Appointment.new(program: @program), :create?
    @vips = @program.vips.ordered
    @held_on_dates = @program.held_on_dates_list
  end

  def create_schedule
    authorize Appointment.new(program: @program), :create?

    unless params[:vip_id].present? && params[:schedule].present?
      redirect_to schedule_builder_department_program_appointments_path(@program.department, @program),
                  alert: "Please select a faculty member and add at least one day with time blocks."
      return
    end

    vip = @program.vips.find(params[:vip_id])
    schedule_blocks = normalize_schedule_params(params[:schedule])

    service = AppointmentScheduleCreatorService.new(@program, vip, schedule_blocks)

    if service.call
      flash[:notice] = "Successfully created #{service.created_count} appointment(s)."
      flash[:alert] = "Some errors occurred: #{service.errors.join('; ')}" if service.errors.any?
    else
      flash[:alert] = "Failed to create appointments: #{service.errors.join('; ')}"
    end

    redirect_to department_program_appointments_path(@program.department, @program)
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_appointment
    @appointment = @program.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:vip_id, :start_time, :end_time)
  end

  def normalize_schedule_params(schedule_params)
    return [] unless schedule_params[:days].present?

    schedule_params[:days].values.map do |day_data|
      {
        date: day_data[:date],
        blocks: normalize_blocks(day_data[:blocks])
      }
    end
  end

  def normalize_blocks(blocks_param)
    return [] unless blocks_param.present?

    # Handle both array and hash formats from form submission
    blocks = blocks_param.is_a?(Array) ? blocks_param : blocks_param.values
    blocks.map do |block|
      {
        type: block[:type] || block["type"] || "single",
        start_time: block[:start_time] || block["start_time"],
        end_time: block[:end_time] || block["end_time"]
      }
    end
  end
end
