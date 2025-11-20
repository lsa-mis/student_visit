class QuestionPolicy < ApplicationPolicy
  def create?
    user&.super_admin? || user&.department_admin_for?(record.questionnaire.program.department)
  end

  def update?
    user&.super_admin? || user&.department_admin_for?(record.questionnaire.program.department)
  end

  def destroy?
    user&.super_admin? || user&.department_admin_for?(record.questionnaire.program.department)
  end
end
