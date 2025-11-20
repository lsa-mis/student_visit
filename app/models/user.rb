class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Alias for compatibility with gems that expect an email method
  def email
    email_address
  end

  # Role helper methods
  def super_admin?
    roles.exists?(name: "super_admin")
  end

  def department_admin?
    roles.exists?(name: "department_admin")
  end

  def student?
    roles.exists?(name: "student")
  end

  def faculty?
    roles.exists?(name: "faculty")
  end

  def has_role?(role_name)
    roles.exists?(name: role_name.to_s)
  end

  def add_role(role_name)
    role = Role.find_or_create_by!(name: role_name.to_s)
    user_roles.find_or_create_by!(role: role)
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name.to_s)
    user_roles.where(role: role).destroy_all if role
  end

  # Department admin methods
  has_many :department_admins, dependent: :destroy
  has_many :administered_departments, through: :department_admins, source: :department

  def department_admin_for?(department)
    return true if super_admin?
    administered_departments.include?(department)
  end

  # Student methods
  has_many :student_programs, dependent: :destroy
  has_many :enrolled_programs, through: :student_programs, source: :program

  def enrolled_in_program?(program)
    enrolled_programs.include?(program)
  end

  def enrolled_departments
    Department.joins(programs: :student_programs)
              .where(student_programs: { user_id: id })
              .distinct
  end

  # Appointment methods
  has_many :appointments, foreign_key: :student_id, dependent: :nullify
  has_many :appointment_selections, dependent: :destroy

  # Answer methods
  has_many :answers, foreign_key: :user_id, dependent: :destroy
end
