require 'rails_helper'

RSpec.describe "Student::Appointments", type: :request do
  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role) }
  let(:vip) { create(:vip, department: department) }

  before do
    create(:student_program, user: student_user, program: program)
  end

  describe "GET /student/departments/:department_id/programs/:program_id/appointments" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get student_department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays my appointments" do
        my_appointment = create(:appointment, :booked, :upcoming, program: program, student: student_user, vip: vip)
        get student_department_program_appointments_path(department, program)
        expect(response.body).to include(my_appointment.vip.display_name)
      end

      it "shows links to available and my appointments pages" do
        get student_department_program_appointments_path(department, program)
        expect(response.body).to include("Available Appointments")
        expect(response.body).to include("My Appointments")
      end

      it "only shows appointments for the program" do
        other_program = create(:program, department: department)
        other_appointment = create(:appointment, :booked, :upcoming, program: other_program, student: student_user, vip: vip)
        get student_department_program_appointments_path(department, program)
        expect(response.body).not_to include(other_appointment.vip.display_name)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get student_department_program_appointments_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when not enrolled in program" do
      let(:other_student) { create(:user, :with_student_role) }

      before { sign_in_as(other_student) }

      it "redirects to dashboard with alert" do
        get student_department_program_appointments_path(department, program)
        expect(response).to redirect_to(student_dashboard_path)
        follow_redirect!
        expect(response.body).to include("not enrolled")
      end
    end
  end

  describe "GET /student/departments/:department_id/programs/:program_id/appointments/available" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get available_student_department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays available appointments" do
        available_appointment = create(:appointment, :available, :upcoming, program: program, vip: vip)
        get available_student_department_program_appointments_path(department, program)
        expect(response.body).to include(available_appointment.vip.display_name)
      end

      it "filters by VIP when vip_id is provided" do
        vip2 = create(:vip, department: department, name: "Dr. Different")
        appointment1 = create(:appointment, :available, :upcoming, program: program, vip: vip,
                              start_time: 1.week.from_now, end_time: 1.week.from_now + 30.minutes)
        appointment2 = create(:appointment, :available, :upcoming, program: program, vip: vip2,
                              start_time: 2.weeks.from_now, end_time: 2.weeks.from_now + 30.minutes)

        get available_student_department_program_appointments_path(department, program), params: { vip_id: vip.id }
        # Check that only the selected VIP's appointments are shown
        # Check that vip.display_name appears in the appointments list (h3 tag)
        expect(response.body).to match(/<h3[^>]*>.*#{Regexp.escape(vip.display_name)}/m)
        # Check that vip2's appointments section doesn't appear - look for vip2's name in h3 tags (appointments list)
        # vip2.display_name will appear in the dropdown, but not in the appointments list
        expect(response.body.scan(/<h3[^>]*>.*#{Regexp.escape(vip2.display_name)}/m).count).to eq(0)
      end

      it "only shows upcoming appointments" do
        past_appointment = create(:appointment, :available, :past, program: program, vip: vip,
                                  start_time: 1.week.ago, end_time: 1.week.ago + 30.minutes)
        upcoming_appointment = create(:appointment, :available, :upcoming, program: program, vip: vip,
                                     start_time: 1.week.from_now, end_time: 1.week.from_now + 30.minutes)

        get available_student_department_program_appointments_path(department, program)
        # Check by appointment date, not VIP name (VIP name appears in dropdown for all VIPs)
        expect(response.body).not_to include(past_appointment.start_time.strftime("%B %d, %Y"))
        expect(response.body).to include(upcoming_appointment.start_time.strftime("%B %d, %Y"))
      end
    end
  end

  describe "GET /student/departments/:department_id/programs/:program_id/appointments/my_appointments" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get my_appointments_student_department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays only my appointments" do
        my_appointment = create(:appointment, :booked, :upcoming, program: program, student: student_user, vip: vip,
                               start_time: 1.week.from_now, end_time: 1.week.from_now + 30.minutes)
        other_student = create(:user, :with_student_role)
        other_vip = create(:vip, department: department, name: "Dr. Other")
        other_appointment = create(:appointment, :booked, :upcoming, program: program, student: other_student, vip: other_vip,
                                  start_time: 2.weeks.from_now, end_time: 2.weeks.from_now + 30.minutes)

        get my_appointments_student_department_program_appointments_path(department, program)
        expect(response.body).to include(my_appointment.vip.display_name)
        expect(response.body).not_to include(other_appointment.vip.display_name)
      end
    end
  end

  describe "POST /student/departments/:department_id/programs/:program_id/appointments/:id/select" do
    let(:appointment) { create(:appointment, :available, :upcoming, program: program, vip: vip) }

    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "selects the appointment" do
        post select_student_department_program_appointment_path(department, program, appointment)
        expect(appointment.reload.student).to eq(student_user)
      end

      it "redirects with success notice" do
        post select_student_department_program_appointment_path(department, program, appointment)
        expect(response).to redirect_to(available_student_department_program_appointments_path(department, program))
        # Flash is set before redirect
        expect(flash[:notice]).to include("selected successfully")
      end

      it "does not allow selecting an already booked appointment" do
        other_student = create(:user, :with_student_role)
        appointment.update!(student: other_student)

        post select_student_department_program_appointment_path(department, program, appointment)
        expect(response).to redirect_to(available_student_department_program_appointments_path(department, program))
        # Flash is set before redirect
        expect(flash[:alert]).to include("no longer available")
      end
    end
  end

  describe "DELETE /student/departments/:department_id/programs/:program_id/appointments/:id/delete" do
    let(:appointment) { create(:appointment, :booked, program: program, student: student_user, vip: vip) }

    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "cancels the appointment" do
        delete delete_student_department_program_appointment_path(department, program, appointment)
        expect(appointment.reload.student).to be_nil
      end

      it "redirects with success notice" do
        delete delete_student_department_program_appointment_path(department, program, appointment)
        expect(response).to redirect_to(my_appointments_student_department_program_appointments_path(department, program))
        # Flash is set before redirect
        expect(flash[:notice]).to include("cancelled successfully")
      end

      it "does not allow cancelling other students' appointments" do
        other_student = create(:user, :with_student_role)
        other_appointment = create(:appointment, :booked, :upcoming, program: program, student: other_student, vip: vip)

        delete delete_student_department_program_appointment_path(department, program, other_appointment)
        expect(response).to have_http_status(:not_found)
        expect(other_appointment.reload.student).to eq(other_student)
      end
    end
  end
end
