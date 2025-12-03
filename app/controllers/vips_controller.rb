class VipsController < ApplicationController
  before_action :set_program
  before_action :set_vip, only: [ :show, :edit, :update, :destroy ]

  def index
    @vips = policy_scope(Vip).where(program: @program).ordered
    authorize Vip.new(program: @program)
  end

  def show
    authorize @vip
  end

  def new
    @vip = @program.vips.build
    authorize @vip
  end

  def create
    @vip = @program.vips.build(vip_params)
    authorize @vip

    if @vip.save
      redirect_to department_program_vip_path(@program.department, @program, @vip), notice: "VIP was successfully created."
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
      redirect_to department_program_vip_path(@program.department, @program, @vip), notice: "VIP was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @vip
    @vip.destroy
    redirect_to department_program_vips_path(@program.department, @program), notice: "VIP was successfully deleted."
  end

  def bulk_upload
    authorize Vip.new(program: @program), :create?
  end

  def process_bulk_upload
    authorize Vip.new(program: @program), :create?

    unless params[:file].present?
      redirect_to bulk_upload_department_program_vips_path(@program.department, @program), alert: "Please select a file."
      return
    end

    service = BulkFacultyUploadService.new(@program, params[:file])
    if service.call
      flash[:notice] = "Successfully uploaded #{service.success_count} VIP(s)."
      flash[:alert] = "#{service.failure_count} failed." if service.failure_count > 0
      flash[:errors] = service.errors if service.errors.any?
    else
      flash[:alert] = "Upload failed: #{service.errors.join(', ')}"
    end

    redirect_to department_program_vips_path(@program.department, @program)
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_vip
    @vip = @program.vips.find(params[:id])
  end

  def vip_params
    params.require(:vip).permit(:name, :profile_url, :title, :ranking)
  end
end
