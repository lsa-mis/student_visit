class StudentMapPolicy < ApplicationPolicy
  def show?
    user&.student?
  end
end
