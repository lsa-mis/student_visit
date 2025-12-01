class Student::DashboardPolicy < ApplicationPolicy
  def show?
    return false unless user
    user.student?
  end
end
