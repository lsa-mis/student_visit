class Student::DashboardPolicy < ApplicationPolicy
  def show?
    return false unless user
    user.student?
  end

  def preview?
    return false unless user
    user.super_admin? || user.department_admin?
  end
end
