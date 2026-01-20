class Student::AppointmentPolicy < ApplicationPolicy
  def index?
    user&.student? || admin_preview_allowed?
  end

  def create?
    user&.student? || false
  end

  def destroy?
    user&.student? || false
  end

  private

  def admin_preview_allowed?
    return false unless user
    user.super_admin? || user.department_admin?
  end
end
