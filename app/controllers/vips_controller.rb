class VipsController < ApplicationController
  before_action :set_department
  before_action :set_vip, only: [:show, :edit, :update, :destroy]

  def index
    @vips = policy_scope(Vip).where(department: @department).ordered
    authorize Vip.new(department: @department)
  end

  def show
    authorize @vip
  end

  def new
    @vip = @department.vips.build
    authorize @vip
  end

  def create
    @vip = @department.vips.build(vip_params)
    authorize @vip

    if @vip.save
      redirect_to department_vip_path(@department, @vip), notice: "VIP was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @vip
  end

  def update
    authorize @vip

    if @vip.update(vip_params)
      redirect_to department_vip_path(@department, @vip), notice: "VIP was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @vip
    @vip.destroy
    redirect_to department_vips_path(@department), notice: "VIP was successfully deleted."
  end

  def bulk_upload
    authorize Vip.new(department: @department), :create?
  end

  def process_bulk_upload
    authorize Vip.new(department: @department), :create?

    unless params[:file].present?
      redirect_to bulk_upload_department_vips_path(@department), alert: "Please select a file."
      return
    end

    service = BulkFacultyUploadService.new(@department, params[:file])
    if service.call
      flash[:notice] = "Successfully uploaded #{service.success_count} VIP(s)."
      flash[:alert] = "#{service.failure_count} failed." if service.failure_count > 0
      flash[:errors] = service.errors if service.errors.any?
    else
      flash[:alert] = "Upload failed: #{service.errors.join(', ')}"
    end

    redirect_to department_vips_path(@department)
  end

  private

  def set_department
    @department = Department.find(params[:department_id])
  end

  def set_vip
    @vip = @department.vips.find(params[:id])
  end

  def vip_params
    params.require(:vip).permit(:name, :profile_url, :title, :ranking)
  end
end
