class StudentsController < ApplicationController
  before_action :set_program
  before_action :set_student, only: [:edit, :update, :destroy]

  def index
    @students = @program.students.order(:email_address)
    authorize @program, :show?
  end

  def edit
    authorize @student
  end

  def update
    authorize @student

    if @student.update(student_params)
      redirect_to department_program_students_path(@department, @program), notice: "Student was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @student

    student_program = @program.student_programs.find_by(user: @student)
    if student_program
      student_program.destroy
      redirect_to department_program_students_path(@department, @program), notice: "Student was successfully removed from the program."
    else
      redirect_to department_program_students_path(@department, @program), alert: "Student is not enrolled in this program."
    end
  end

  def bulk_upload
    authorize @program, :update?
  end

  def process_bulk_upload
    authorize @program, :update?

    unless params[:file].present?
      redirect_to bulk_upload_department_program_students_path(@program.department, @program), alert: "Please select a file."
      return
    end

    service = BulkStudentUploadService.new(@program, params[:file])
    if service.call
      flash[:notice] = "Successfully uploaded #{service.success_count} student(s)."
      flash[:alert] = "#{service.failure_count} failed." if service.failure_count > 0
      flash[:errors] = service.errors if service.errors.any?
    else
      flash[:alert] = "Upload failed: #{service.errors.join(', ')}"
    end

    redirect_to department_program_students_path(@program.department, @program)
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_student
    @student = @program.students.find(params[:id])
  end

  def student_params
    params.require(:user).permit(:email_address, :last_name, :first_name, :umid)
  end
end
