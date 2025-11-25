class StudentCalendarPolicy < ApplicationPolicy
  def show?
    user&.student?
  end
end
