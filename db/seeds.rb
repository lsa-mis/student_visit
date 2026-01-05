# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
require "securerandom"
# Do not seed production.
if Rails.env.production?
  puts "Skipping db:seed in production environment."
else
# Create initial roles
Role::ROLE_TYPES.each do |role_name|
  Role.find_or_create_by!(name: role_name)
end

# Bootstrap a minimal working dataset for a fresh install.
#
# NOTE: This is intentionally idempotent. Re-running seeds will not reset
# existing users' passwords; it will only create missing records and ensure the
# correct roles/associations exist.

super_admin_email = "samplesuperadmin@example.com"
super_admin_password = ENV.fetch("SUPER_ADMIN_PASSWORD") { SecureRandom.hex(16) }

super_admin = User.find_or_initialize_by(email_address: super_admin_email)
if super_admin.new_record?
  super_admin.password = super_admin_password
  super_admin.password_confirmation = super_admin_password
  super_admin.save!
  puts "Created super admin user: #{super_admin_email}"
end

super_admin.add_role("super_admin") unless super_admin.super_admin?

department = Department.find_or_create_by!(name: "Butterfly Science")

dept_admin_email = "sampledeptadmin@example.com"
dept_admin_password = ENV.fetch("DEPT_ADMIN_PASSWORD") { SecureRandom.hex(16) }

dept_admin = User.find_or_initialize_by(email_address: dept_admin_email)
if dept_admin.new_record?
  dept_admin.password = dept_admin_password
  dept_admin.password_confirmation = dept_admin_password
  dept_admin.save!
  puts "Created department admin user: #{dept_admin_email} "
end

dept_admin.add_role("department_admin") unless dept_admin.department_admin?
DepartmentAdmin.find_or_create_by!(user: dept_admin, department: department)
end
