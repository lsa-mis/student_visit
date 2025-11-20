class DepartmentAdminsController < ApplicationController
  before_action :set_department

  def index
    @department_admins = @department.department_admins.includes(:user)
    @users = User.order(:email_address)
    authorize @department, :update?
  end

  def create
    authorize @department, :update?

    # Check if user_id is provided (existing user) or email_address (new user)
    if params[:user_id].present?
      user = User.find(params[:user_id])
    elsif params[:email_address].present?
      # Create new user if they don't exist
      user = User.find_or_initialize_by(email_address: params[:email_address].strip.downcase)

      if user.new_record?
        # Generate a temporary password - user will need to reset it
        user.password = SecureRandom.hex(16)
        unless user.save
          @department_admins = @department.department_admins.includes(:user)
          @users = User.order(:email_address)
          flash.now[:alert] = "Error creating user: #{user.errors.full_messages.join(', ')}"
          render :index, status: :unprocessable_entity
          return
        end

        # Send welcome email with password reset link to new user
        DepartmentAdminMailer.welcome(user, @department).deliver_later
      end
    else
      @department_admins = @department.department_admins.includes(:user)
      @users = User.order(:email_address)
      flash.now[:alert] = "Please select a user or enter an email address."
      render :index, status: :unprocessable_entity
      return
    end

    # Ensure user has department_admin role
    user.add_role("department_admin") unless user.department_admin?

    # Create department admin association
    @department_admin = @department.department_admins.build(user: user)

    if @department_admin.save
      redirect_to department_admins_path(@department), notice: "Department admin was successfully added."
    else
      @department_admins = @department.department_admins.includes(:user)
      @users = User.order(:email_address)
      flash.now[:alert] = "Error adding department admin: #{@department_admin.errors.full_messages.join(', ')}"
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @department_admin = @department.department_admins.find(params[:id])
    authorize @department, :update?
    @department_admin.destroy
    redirect_to department_admins_path(@department), notice: "Department admin was successfully removed."
  end

  private

  def set_department
    @department = Department.find(params[:department_id])
  end
end
