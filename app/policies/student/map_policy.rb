class Student::MapPolicy < ApplicationPolicy
  def show?
    user&.student?
  end
end
