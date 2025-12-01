class Admin::ReportsController < ApplicationController
  before_action :set_program

  def students
    authorize @program, :show?
    @students = @program.students.includes(:answers, :appointments).order(:email_address)

    respond_to do |format|
      format.html
      format.csv do
        send_data CsvExportService.export_students(@program),
                  filename: "students-#{@program.name.parameterize}-#{Date.current}.csv",
                  type: "text/csv"
      end
    end
  end

  def appointments
    authorize @program, :show?

    @view = params[:view] || "faculty"
    @vips = @program.department.vips.ordered
    @students = @program.students.order(:email_address)

    respond_to do |format|
      format.html
      format.csv do
        csv_data = if @view == "student"
          CsvExportService.export_appointments_by_student(@program)
        else
          CsvExportService.export_appointments_by_faculty(@program)
        end

        send_data csv_data,
                  filename: "appointments-#{@view}-#{@program.name.parameterize}-#{Date.current}.csv",
                  type: "text/csv"
      end
    end
  end

  def calendar
    authorize @program, :show?

    @students = @program.students.order(:email_address)
    @student = User.find(params[:student_id]) if params[:student_id].present?
    @date = params[:date] ? Date.parse(params[:date]) : nil

    respond_to do |format|
      format.html
      format.csv do
        unless @student
          redirect_to calendar_admin_department_program_reports_path(@program.department, @program),
                      alert: "Please select a student."
          return
        end

        send_data CsvExportService.export_calendar(@student, @program, @date),
                  filename: "calendar-#{@student.email_address.parameterize}-#{Date.current}.csv",
                  type: "text/csv"
      end
    end
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end
end
