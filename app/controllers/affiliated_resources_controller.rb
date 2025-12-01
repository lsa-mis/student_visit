class AffiliatedResourcesController < ApplicationController
  before_action :set_department
  before_action :set_affiliated_resource, only: [ :edit, :update, :destroy ]

  def index
    @affiliated_resources = @department.affiliated_resources.ordered
    authorize AffiliatedResource.new(department: @department)
  end

  def new
    @affiliated_resource = @department.affiliated_resources.build
    authorize @affiliated_resource
  end

  def create
    @affiliated_resource = @department.affiliated_resources.build(affiliated_resource_params)
    authorize @affiliated_resource

    if @affiliated_resource.save
      redirect_to department_affiliated_resource_path(@department, @affiliated_resource), notice: "Affiliated resource was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @affiliated_resource
  end

  def update
    authorize @affiliated_resource

    if @affiliated_resource.update(affiliated_resource_params)
      redirect_to department_affiliated_resource_path(@department, @affiliated_resource), notice: "Affiliated resource was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @affiliated_resource
    @affiliated_resource.destroy
    redirect_to department_affiliated_resources_path(@department), notice: "Affiliated resource was successfully deleted."
  end

  private

  def set_department
    @department = Department.find(params[:department_id])
  end

  def set_affiliated_resource
    @affiliated_resource = @department.affiliated_resources.find(params[:id])
  end

  def affiliated_resource_params
    params.require(:affiliated_resource).permit(:name, :url, :position)
  end
end
