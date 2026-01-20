class Student::MapPolicy < ApplicationPolicy
  def show?
    user&.student? || admin_preview_allowed?
  end

  private

  def admin_preview_allowed?
    return false unless user
    user.super_admin? || user.department_admin?
  end
end
