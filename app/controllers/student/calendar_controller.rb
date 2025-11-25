class Student::CalendarController < ApplicationController
  before_action :set_program
  before_action :ensure_enrolled

  def show
    authorize :student_calendar, :show?

    @filter_mode = params[:filter] || "all" # date or all
    @view_mode = params[:view] || (@filter_mode == "all" ? nil : "single") # single or multi (nil when showing all)

    # Set date: use provided date, or if switching to date filter mode, use first held-on date, otherwise current date
    if params[:date]
      @date = Date.parse(params[:date])
    elsif @filter_mode == "date" && @program.held_on_dates.present? && @program.held_on_dates.is_a?(Array) && @program.held_on_dates.any?
      @date = @program.held_on_dates_list.first
    else
      @date = Date.current
    end

    if @filter_mode == "all"
      # Show all events for the program
      @calendar_events = @program.calendar_events.order(:start_time)
      @my_appointments = @program.appointments
                                 .for_student(current_user)
                                 .includes(:vip)
                                 .order(:start_time)
    elsif @view_mode == "single"
      # Single day view
      @calendar_events = @program.calendar_events
                                  .where(start_time: @date.beginning_of_day..@date.end_of_day)
                                  .order(:start_time)
      @my_appointments = @program.appointments
                                 .for_student(current_user)
                                 .where(start_time: @date.beginning_of_day..@date.end_of_day)
                                 .includes(:vip)
                                 .order(:start_time)
    else
      # Week view
      start_date = @date.beginning_of_week
      end_date = @date.end_of_week
      @calendar_events = @program.calendar_events
                                  .where(start_time: start_date..end_date)
                                  .order(:start_time)
      @my_appointments = @program.appointments
                                 .for_student(current_user)
                                 .where(start_time: start_date..end_date)
                                 .includes(:vip)
                                 .order(:start_time)
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
