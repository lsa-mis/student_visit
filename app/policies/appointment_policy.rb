class AppointmentPolicy < ApplicationPolicy
  def index?
    return false unless user
    # Department admins can only access appointment indexes for programs in their own department.
    return true if user.super_admin?

    record_program = record.respond_to?(:program) ? record.program : nil
    return false unless record_program

    user.department_admin_for?(record_program.department)
  end

  def show?
    return false unless user

    return true if user.super_admin?

    record_program = record.respond_to?(:program) ? record.program : nil
    return false unless record_program

    user.department_admin_for?(record_program.department)
  end

  def create?
    return false unless user

    return true if user.super_admin?

    record_program = record.respond_to?(:program) ? record.program : nil
    return false unless record_program

    user.department_admin_for?(record_program.department)
  end

  def update?
    return false unless user

    return true if user.super_admin?

    record_program = record.respond_to?(:program) ? record.program : nil
    return false unless record_program

    user.department_admin_for?(record_program.department)
  end

  def destroy?
    return false unless user

    return true if user.super_admin?

    record_program = record.respond_to?(:program) ? record.program : nil
    return false unless record_program

    user.department_admin_for?(record_program.department)
  end

  class Scope < Scope
    def resolve
      if user&.super_admin?
        scope.all
      elsif user&.department_admin?
        scope.joins(program: { department: :department_admins })
             .where(department_admins: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
