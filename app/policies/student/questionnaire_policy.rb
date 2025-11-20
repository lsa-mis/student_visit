class Student::QuestionnairePolicy < ApplicationPolicy
  def index?
    user&.student?
  end

  def show?
    user&.student?
  end

  def edit?
    user&.student?
  end

  def update?
    user&.student?
  end
end
