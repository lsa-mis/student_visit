module AuthenticationHelpers
  def sign_in_as(user)
    session = user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1')
    signed_value = signed_session_cookie(session.id)

    if defined?(Capybara) && respond_to?(:page)
      set_capaybara_session_cookie(signed_value)
    elsif respond_to?(:cookies) && cookies.respond_to?(:signed)
      # Controller specs - use signed cookies directly
      cookies.signed[:session_id] = session.id
    else
      # Request specs - manually add the signed cookie to Rack::Test
      cookies[:session_id] = signed_value
    end
  end

  def signed_session_cookie(session_id)
    key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base, iterations: 1000)
    secret = key_generator.generate_key('signed cookie')
    ActiveSupport::MessageVerifier.new(secret).generate(session_id)
  end

  def set_capaybara_session_cookie(signed_value)
    driver = page.driver
    if driver.respond_to?(:browser) && driver.browser.respond_to?(:manage)
      driver.browser.manage.add_cookie(name: 'session_id', value: signed_value, path: '/')
    elsif driver.respond_to?(:browser) && driver.browser.respond_to?(:set_cookie)
      driver.browser.set_cookie("session_id=#{signed_value}; path=/")
    elsif driver.respond_to?(:set_cookie)
      driver.set_cookie('session_id', signed_value)
    else
      raise "Unsupported Capybara driver for authentication helper: #{driver.class}"
    end
  end

  def sign_in_as_super_admin(email: nil)
    email ||= "superadmin#{SecureRandom.hex(4)}@example.com"
    user = User.create!(email_address: email, password: 'password123')
    user.add_role('super_admin')
    sign_in_as(user)
    user
  end

  def sign_in_as_department_admin(department = nil, email: nil)
    email ||= "deptadmin#{SecureRandom.hex(4)}@example.com"
    user = User.create!(email_address: email, password: 'password123')
    user.add_role('department_admin')
    if department
      DepartmentAdmin.create!(user: user, department: department)
    end
    sign_in_as(user)
    user
  end

  def sign_in_as_student(email: nil, enrolled_in: nil)
    email ||= "student#{SecureRandom.hex(4)}@example.com"
    user = User.create!(email_address: email, password: 'password123')
    user.add_role('student')
    if enrolled_in
      StudentProgram.create!(user: user, program: enrolled_in)
    end
    sign_in_as(user)
    user
  end

  def sign_out
    cookies.delete(:session_id)
  end
end
