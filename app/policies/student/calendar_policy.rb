class Student::CalendarPolicy < ApplicationPolicy
  def show?
    user&.student?
  end
end
