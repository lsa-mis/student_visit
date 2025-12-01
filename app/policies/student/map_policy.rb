class Student::MapPolicy < ApplicationPolicy
  def show?
    user&.student? || false
  end
end
