class DepartmentsController < ApplicationController
  before_action :set_department, only: [:show, :edit, :update, :destroy]

  def index
    @departments = policy_scope(Department).order(:name)
    authorize Department
  end

  def show
    authorize @department
    @programs = @department.programs.order(active: :desc, created_at: :desc)
    @vips = @department.vips.ordered
    @affiliated_resources = @department.affiliated_resources.ordered
  end

  def edit_content
    authorize @department
  end

  def update_content
    authorize @department

    if @department.update(department_content_params)
      redirect_to department_path(@department), notice: "Department content was successfully updated."
    else
      render :edit_content, status: :unprocessable_entity
    end
  end

  def new
    @department = Department.new
    authorize @department
  end

  def create
    @department = Department.new(department_params)
    authorize @department

    if @department.save
      redirect_to @department, notice: "Department was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @department
  end

  def update
    authorize @department

    if @department.update(department_params)
      redirect_to @department, notice: "Department was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @department
    @department.destroy
    redirect_to departments_path, notice: "Department was successfully deleted."
  end

  private

  def set_department
    @department = Department.find(params[:id])
  end

  def department_params
    params.require(:department).permit(:name, :street_address, :google_map_url)
  end

  def department_content_params
    params.require(:department).permit(:mission_statement, :image)
  end
end
