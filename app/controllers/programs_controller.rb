class ProgramsController < ApplicationController
  before_action :set_department
  before_action :set_program, only: [:show, :edit, :update, :destroy]

  def index
    @programs = policy_scope(Program).where(department: @department).order(active: :desc, created_at: :desc)
    authorize Program
  end

  def show
    authorize @program
  end

  def new
    @program = @department.programs.build
    authorize @program
  end

  def create
    @program = @department.programs.build(program_params)
    authorize @program

    if @program.save
      redirect_to [@department, @program], notice: "Program was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @program
  end

  def update
    authorize @program

    if @program.update(program_params)
      redirect_to [@department, @program], notice: "Program was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @program
    @program.destroy
    redirect_to department_programs_path(@department), notice: "Program was successfully deleted."
  end

  private

  def set_department
    @department = Department.find(params[:department_id])
  end

  def set_program
    @program = @department.programs.find(params[:id])
  end

  def program_params
    params.require(:program).permit(:name, :open_date, :close_date, :questionnaire_due_date, :default_appointment_length, :active, :google_map_url)
  end
end
