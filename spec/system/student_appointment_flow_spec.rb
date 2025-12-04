require 'rails_helper'

RSpec.describe "Student Appointment Flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role, email_address: "student@example.com", password: "password123") }
  let(:vip) { create(:vip, program: program, name: "Dr. Smith") }

  before do
    create(:student_program, user: student_user, program: program)
  end

  it "allows student to view and select an available appointment" do
    appointment = create(:appointment, :available, :upcoming, program: program, vip: vip,
                        start_time: 1.week.from_now, end_time: 1.week.from_now + 30.minutes)

    sign_in_as(student_user)
    visit available_student_department_program_appointments_path(department, program)

    expect(page).to have_content(vip.display_name, wait: 5)
    expect(page).to have_content(appointment.start_time.strftime("%B %d, %Y"), wait: 5)

    # Find and click the select button for this appointment
    # The view groups appointments by VIP, so find the appointment's container
    # Wait for the button to be present
    select_button = find("input[type='submit'][value='Select']", wait: 5)
    select_button.click

    # Wait for redirect and check appointment was selected
    expect(page).to have_content("Available Appointments", wait: 5)
    expect(appointment.reload.student).to eq(student_user)
  end

  it "allows student to view and cancel their appointment" do
    appointment = create(:appointment, :booked, program: program, student: student_user, vip: vip,
                        start_time: 1.week.from_now, end_time: 1.week.from_now + 30.minutes)

    sign_in_as(student_user)
    visit my_appointments_student_department_program_appointments_path(department, program)

    expect(page).to have_content(vip.display_name, wait: 5)
    expect(page).to have_content(appointment.start_time.strftime("%B %d, %Y"), wait: 5)

    # Find and click the cancel button for this appointment
    # Wait for the button to be present
    cancel_button = find("input[type='submit'][value='Cancel']", wait: 5)
    cancel_button.click

    # Wait for redirect and check appointment was cancelled
    expect(page).to have_content("My Appointments", wait: 5)
    expect(appointment.reload.student).to be_nil
  end

  it "filters appointments by VIP" do
    vip2 = create(:vip, program: program, name: "Dr. Jones")
    appointment1 = create(:appointment, :available, :upcoming, program: program, vip: vip,
                          start_time: 1.week.from_now, end_time: 1.week.from_now + 30.minutes)
    appointment2 = create(:appointment, :available, :upcoming, program: program, vip: vip2,
                          start_time: 2.weeks.from_now, end_time: 2.weeks.from_now + 30.minutes)

    sign_in_as(student_user)
    visit available_student_department_program_appointments_path(department, program, vip_id: vip.id)

    expect(page).to have_css("h3", text: vip.display_name, wait: 5)
    expect(page).not_to have_css("h3", text: vip2.display_name, wait: 2)
  end
end
