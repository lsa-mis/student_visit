class StudentDashboardPolicy < ApplicationPolicy
  def show?
    user&.student?
  end
end
