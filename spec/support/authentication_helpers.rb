module AuthenticationHelpers
  def sign_in_as(user)
    session = user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1')

    # In request specs, manually sign the cookie using Rails' cookie signing mechanism
    # Rack::Test doesn't support cookies.signed, so we need to use the same signing Rails uses
    if respond_to?(:cookies) && cookies.respond_to?(:signed)
      # Controller specs - use signed cookies directly
      cookies.signed[:session_id] = session.id
    else
      # Request specs - manually sign using Rails' cookie signing
      # Rails uses ActionDispatch::Cookies::CookieJar for signed cookies
      # We need to use the same key generator and verifier Rails uses
      key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000)
      secret = key_generator.generate_key('signed cookie')
      verifier = ActiveSupport::MessageVerifier.new(secret)
      signed_value = verifier.generate(session.id)
      # Set the cookie - Rack::Test will include it in the request
      cookies[:session_id] = signed_value
    end
  end

  def sign_in_as_super_admin
    user = User.create!(email_address: 'superadmin@example.com', password: 'password123')
    user.add_role('super_admin')
    sign_in_as(user)
    user
  end

  def sign_in_as_department_admin(department = nil)
    user = User.create!(email_address: 'deptadmin@example.com', password: 'password123')
    user.add_role('department_admin')
    if department
      DepartmentAdmin.create!(user: user, department: department)
    end
    sign_in_as(user)
    user
  end

  def sign_in_as_student
    user = User.create!(email_address: 'student@example.com', password: 'password123')
    user.add_role('student')
    sign_in_as(user)
    user
  end

  def sign_out
    cookies.delete(:session_id)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :controller
end
