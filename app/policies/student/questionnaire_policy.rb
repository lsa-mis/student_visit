class Student::QuestionnairePolicy < ApplicationPolicy
  def index?
    user&.student? || admin_preview_allowed?
  end

  def show?
    user&.student? || admin_preview_allowed?
  end

  def edit?
    user&.student? || false
  end

  def update?
    user&.student? || false
  end

  private

  def admin_preview_allowed?
    return false unless user
    user.super_admin? || user.department_admin?
  end
end
