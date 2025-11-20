class Student::CalendarController < ApplicationController
  before_action :set_program
  before_action :ensure_enrolled

  def show
    authorize :student_calendar, :show?

    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @view_mode = params[:view] || "single" # single or multi

    if @view_mode == "single"
      @calendar_events = @program.calendar_events
                                  .where(start_time: @date.beginning_of_day..@date.end_of_day)
                                  .order(:start_time)
      @my_appointments = @program.appointments
                                 .for_student(current_user)
                                 .where(start_time: @date.beginning_of_day..@date.end_of_day)
                                 .includes(:vip)
                                 .order(:start_time)
    else
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
