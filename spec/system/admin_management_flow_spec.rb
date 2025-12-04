require 'rails_helper'

RSpec.describe "Admin Management Flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:department) { create(:department, :with_active_program, name: "Physics Department") }
  let(:program) { department.active_program }
  let!(:vip) { create(:vip, program: program, name: "Dr. Ada Lovelace") }
  let!(:questionnaire) { create(:questionnaire, program: program, name: "Campus Experience Survey") }
  let!(:question) { create(:question, questionnaire: questionnaire, text: "How was your visit?") }
  let!(:calendar_event) { create(:calendar_event, :upcoming, program: program, title: "Campus Tour") }
  let!(:appointment) { create(:appointment, :available, :upcoming, program: program, vip: vip) }
  let!(:student) { create(:user, :with_student_role, email_address: "admin-flow-student@example.com") }

  before do
    create(:student_program, user: student, program: program)
    sign_in_as_super_admin
  end

  it "allows super admins to navigate core management pages" do
    visit departments_path
    expect(page).to have_content("Departments")
    expect(page).to have_content(department.name)

    click_link department.name, match: :first
    expect(page).to have_content("Programs")

    click_link program.name, match: :first
    expect(page).to have_content(program.name)
    expect(page).to have_content("Program Management")
    expect(page).to have_content("VIPs (Faculty/Staff)")

    click_link "Questionnaires"
    expect(page).to have_content("Questionnaires")
    expect(page).to have_content(questionnaire.name)

    visit department_program_calendar_events_path(department, program)
    expect(page).to have_content("Calendar Events")
    expect(page).to have_content(calendar_event.title)

    visit department_program_appointments_path(department, program)
    expect(page).to have_content("Appointments")
    expect(page).to have_content(vip.display_name)

    visit department_program_students_path(department, program)
    expect(page).to have_content("Students")
    expect(page).to have_content(student.email_address)

    visit department_program_vips_path(department, program)
    expect(page).to have_content("VIPs (Faculty/Staff)")
    expect(page).to have_content(vip.name)
  end
end
