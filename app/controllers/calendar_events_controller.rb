class CalendarEventsController < ApplicationController
  before_action :set_program
  before_action :set_calendar_event, only: [:show, :edit, :update, :destroy]

  def index
    @calendar_events = @program.calendar_events.order(:start_time)
    authorize CalendarEvent.new(program: @program)
  end

  def show
    authorize @calendar_event
  end

  def new
    @calendar_event = @program.calendar_events.build
    authorize @calendar_event
    @vips = @program.department.vips.ordered
  end

  def create
    @calendar_event = @program.calendar_events.build(calendar_event_params)
    authorize @calendar_event
    @vips = @program.department.vips.ordered

    if @calendar_event.save
      update_participating_faculty
      redirect_to department_program_calendar_events_path(@program.department, @program), notice: "Calendar event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @calendar_event
    @vips = @program.department.vips.ordered
  end

  def update
    authorize @calendar_event
    @vips = @program.department.vips.ordered

    if @calendar_event.update(calendar_event_params)
      update_participating_faculty
      redirect_to department_program_calendar_event_path(@program.department, @program, @calendar_event), notice: "Calendar event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @calendar_event
    @calendar_event.destroy
    redirect_to department_program_calendar_events_path(@program.department, @program), notice: "Calendar event was successfully deleted."
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_calendar_event
    @calendar_event = @program.calendar_events.find(params[:id])
  end

  def calendar_event_params
    params.require(:calendar_event).permit(:title, :description, :start_time, :end_time)
  end

  def update_participating_faculty
    vip_ids = params[:calendar_event][:vip_ids]&.reject(&:blank?) || []
    @calendar_event.participating_faculty = @program.department.vips.where(id: vip_ids)
  end
end
