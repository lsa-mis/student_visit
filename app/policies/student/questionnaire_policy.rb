class Student::QuestionnairePolicy < ApplicationPolicy
  def index?
    user&.student? || false
  end

  def show?
    user&.student? || false
  end

  def edit?
    user&.student? || false
  end

  def update?
    user&.student? || false
  end
end
