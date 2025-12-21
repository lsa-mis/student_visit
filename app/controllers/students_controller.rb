class StudentsController < ApplicationController
  before_action :set_program
  before_action :set_student, only: [ :edit, :update, :destroy ]

  def index
    @students = @program.students.order(:email_address)
    authorize @program, :show?
  end

  def search
    authorize @program, :update?

    query = params[:q]&.strip&.downcase
    return render json: [] if query.blank? || query.length < 2

    users = User.where("LOWER(email_address) LIKE ?", "%#{query}%")
                .order(:email_address)
                .limit(10)
                .select(:id, :email_address, :last_name, :first_name, :umid)

    render json: users.map { |u| { id: u.id, email_address: u.email_address, last_name: u.last_name, first_name: u.first_name, umid: u.umid } }
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

  def create
    authorize @program, :update?

    # Email address is required
    unless params[:email_address].present?
      @students = @program.students.order(:email_address)
      flash.now[:alert] = "Email address is required."
      render :index, status: :unprocessable_entity
      return
    end

    email = params[:email_address].strip.downcase

    # Check if UMID is provided (required)
    unless params[:umid].present?
      @students = @program.students.order(:email_address)
      flash.now[:alert] = "UMID is required."
      render :index, status: :unprocessable_entity
      return
    end

    # Find or initialize user
    user = User.find_or_initialize_by(email_address: email)
    formatted_umid = format_umid(params[:umid])
    was_new_record = user.new_record?

    # Check if UMID is already taken by another user
    if formatted_umid.present? && User.where.not(id: user.id).exists?(umid: formatted_umid)
      @students = @program.students.order(:email_address)
      flash.now[:alert] = "This UMID is already in use by another student."
      render :index, status: :unprocessable_entity
      return
    end

    if was_new_record
      # Create new user - UMID is required
      user.last_name = params[:last_name]&.strip if params[:last_name].present?
      user.first_name = params[:first_name]&.strip if params[:first_name].present?
      user.umid = formatted_umid

      # Set initial password to UMID - user will be required to change it on first login
      user.password = formatted_umid
      user.must_change_password = true

      unless user.save
        @students = @program.students.order(:email_address)
        flash.now[:alert] = "Error creating user: #{user.errors.full_messages.join(', ')}"
        render :index, status: :unprocessable_entity
        return
      end

      # Add student role
      user.add_role("student") unless user.student?
    else
      # Student already exists - check if already in program
      if @program.student_programs.exists?(user: user)
        redirect_to department_program_students_path(@department, @program), alert: "This student is already enrolled in the program."
        return
      end
      # Student exists but not in program - will be added below
    end

    # Ensure user has student role
    user.add_role("student") unless user.student?

    # Enroll in program
    student_program = @program.student_programs.find_or_initialize_by(user: user)

    if student_program.new_record?
      if student_program.save
        # Send welcome email to newly created students
        StudentMailer.welcome(user, @program).deliver_later if was_new_record
        redirect_to department_program_students_path(@department, @program), notice: "Student was successfully added to the program."
      else
        @students = @program.students.order(:email_address)
        flash.now[:alert] = "Error enrolling student: #{student_program.errors.full_messages.join(', ')}"
        render :index, status: :unprocessable_entity
      end
    else
      redirect_to department_program_students_path(@department, @program), alert: "This student is already enrolled in the program."
    end
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

  def format_umid(value)
    return nil if value.nil?

    # Convert to string and remove any whitespace
    umid_str = value.to_s.strip

    # If it's a numeric value (integer or float), format it as an 8-digit string with leading zeros
    if umid_str.match?(/^\d+(\.0+)?$/)
      # Remove decimal point and trailing zeros if present (e.g., "1234567.0" -> "1234567")
      umid_str = umid_str.split(".").first
      # Pad with leading zeros to ensure 8 digits
      umid_str.rjust(8, "0")
    else
      # Already a string, use as-is
      umid_str
    end
  end
end
