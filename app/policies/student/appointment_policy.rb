class Student::AppointmentPolicy < ApplicationPolicy
  def index?
    user&.student?
  end

  def create?
    user&.student?
  end

  def destroy?
    user&.student?
  end
end
