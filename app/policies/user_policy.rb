class UserPolicy < ApplicationPolicy
  def index?
    user&.super_admin?
  end

  def show?
    return true if user&.super_admin?
    return true if user == record

    # Department admins can view students enrolled in their programs
    if user&.department_admin? && record.student?
      user.administered_departments.joins(programs: :student_programs)
          .where(student_programs: { user_id: record.id })
          .exists?
    else
      false
    end
  end

  def create?
    user&.super_admin?
  end

  def update?
    return true if user&.super_admin?
    return true if user == record

    # Department admins can update students enrolled in their programs
    if user&.department_admin? && record.student?
      user.administered_departments.joins(programs: :student_programs)
          .where(student_programs: { user_id: record.id })
          .exists?
    else
      false
    end
  end

  def destroy?
    return true if user&.super_admin?

    # Department admins can remove students from their programs
    if user&.department_admin? && record.student?
      user.administered_departments.joins(programs: :student_programs)
          .where(student_programs: { user_id: record.id })
          .exists?
    else
      false
    end
  end

  class Scope < Scope
    def resolve
      if user&.super_admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
