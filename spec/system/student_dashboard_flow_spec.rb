require 'rails_helper'

RSpec.describe "Student Dashboard Flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role, email_address: "student@example.com", password: "password123") }

  before do
    create(:student_program, user: student_user, program: program)
  end

  it "allows student to log in and view dashboard" do
    visit new_session_path

    fill_in "email_address", with: student_user.email_address
    fill_in "password", with: "password123"
    button = find_button("Sign in", wait: 5)
    button.click

    expect(current_path).to eq(student_dashboard_path)
    expect(page).to have_content(department.name, wait: 5)
    expect(page).to have_content(program.name, wait: 5)
  end

  it "allows student to select department when enrolled in multiple" do
    department2 = create(:department, :with_active_program)
    program2 = department2.active_program
    create(:student_program, user: student_user, program: program2)

    visit new_session_path
    fill_in "email_address", with: student_user.email_address
    fill_in "password", with: "password123"
    button = find_button("Sign in", wait: 5)
    button.click
    visit student_dashboard_path

    expect(page).to have_content("Select Department", wait: 5)

    expect(page).to have_select("department_id", wait: 5)
    select department.name, from: "department_id"
    # Form auto-submits on change, wait for redirect
    expect(page).to have_content(department.name, wait: 5)
  end

  it "shows navigation links when department is selected" do
    visit new_session_path
    fill_in "email_address", with: student_user.email_address
    fill_in "password", with: "password123"
    button = find_button("Sign in", wait: 5)
    button.click
    visit student_dashboard_path

    # Auto-selects when only one department, wait for page to load
    expect(page).to have_content("Questionnaires", wait: 5)
    expect(page).to have_content("Appointments", wait: 5)
    expect(page).to have_content("Calendar", wait: 5)
    expect(page).to have_content("Map", wait: 5)
  end
end
