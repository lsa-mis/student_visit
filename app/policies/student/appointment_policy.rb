class Student::AppointmentPolicy < ApplicationPolicy
  def index?
    user&.student? || false
  end

  def create?
    user&.student? || false
  end

  def destroy?
    user&.student? || false
  end
end
