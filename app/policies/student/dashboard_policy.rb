class Student::DashboardPolicy < ApplicationPolicy
  def show?
    user&.student?
  end
end
