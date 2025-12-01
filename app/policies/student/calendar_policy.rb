class Student::CalendarPolicy < ApplicationPolicy
  def show?
    user&.student? || false
  end
end
