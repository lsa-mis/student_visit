# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create initial roles
Role::ROLE_TYPES.each do |role_name|
  Role.find_or_create_by!(name: role_name)
end

# Create default super admin user (only in development/test)
if Rails.env.development? || Rails.env.test?
  super_admin_email = "admin@example.com"
  super_admin = User.find_or_initialize_by(email_address: super_admin_email)

  if super_admin.new_record?
    super_admin.password = "password123"
    super_admin.password_confirmation = "password123"
    super_admin.save!
    puts "Created super admin user: #{super_admin_email} / password123"
  end

  # Ensure super admin has the super_admin role
  unless super_admin.super_admin?
    super_admin.add_role("super_admin")
    puts "Assigned super_admin role to #{super_admin_email}"
  end
end
