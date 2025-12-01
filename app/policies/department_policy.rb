class DepartmentPolicy < ApplicationPolicy
  def index?
    user&.super_admin? || user&.department_admin?
  end

  def show?
    user&.super_admin? || user&.department_admin_for?(record)
  end

  def create?
    user&.super_admin?
  end

  def update?
    user&.super_admin? || user&.department_admin_for?(record)
  end

  def destroy?
    user&.super_admin?
  end

  class Scope < Scope
    def resolve
      if user&.super_admin?
        scope.all
      elsif user&.department_admin?
        scope.joins(:department_admins).where(department_admins: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
