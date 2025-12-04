require 'rails_helper'

RSpec.describe "Student::Calendar", type: :request do
  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role) }
  let(:vip) { create(:vip, program: program) }

  before do
    create(:student_program, user: student_user, program: program)
  end

  describe "GET /student/departments/:department_id/programs/:program_id/calendar" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get student_department_program_calendar_path(department, program)
        expect(response).to have_http_status(:success)
      end

      context "with filter_mode 'all'" do
        it "displays all calendar events" do
          event1 = create(:calendar_event, program: program, start_time: 1.week.ago)
          event2 = create(:calendar_event, program: program, start_time: 1.week.from_now)

          get student_department_program_calendar_path(department, program), params: { filter: "all" }
          expect(response.body).to include(event1.title)
          expect(response.body).to include(event2.title)
        end

        it "displays all appointments" do
          appointment1 = create(:appointment, :booked, :past, program: program, student: student_user, vip: vip)
          appointment2 = create(:appointment, :booked, :upcoming, program: program, student: student_user, vip: vip)

          get student_department_program_calendar_path(department, program), params: { filter: "all" }
          expect(response.body).to include(vip.name)
        end
      end

      context "with filter_mode 'date' and view_mode 'single'" do
        let(:date) { Date.current }

        it "displays events for the specified date" do
          event_today = create(:calendar_event, program: program, start_time: date.beginning_of_day + 10.hours)
          event_tomorrow = create(:calendar_event, program: program, start_time: date.tomorrow.beginning_of_day + 10.hours)

          get student_department_program_calendar_path(department, program), params: { filter: "date", view: "single", date: date.to_s }
          expect(response.body).to include(event_today.title)
          expect(response.body).not_to include(event_tomorrow.title)
        end

        it "displays appointments for the specified date" do
          appointment_today = create(:appointment, :booked, program: program, student: student_user, vip: vip, start_time: date.beginning_of_day + 14.hours)
          appointment_tomorrow = create(:appointment, :booked, program: program, student: student_user, vip: vip, start_time: date.tomorrow.beginning_of_day + 14.hours)

          get student_department_program_calendar_path(department, program), params: { filter: "date", view: "single", date: date.to_s }
          expect(response.body).to include(vip.name)
        end
      end

      context "with filter_mode 'date' and view_mode 'multi' (week view)" do
        let(:date) { Date.current }

        it "displays events for the week" do
          event_this_week = create(:calendar_event, program: program, start_time: date.beginning_of_week + 2.days, end_time: date.beginning_of_week + 2.days + 1.hour)
          event_next_week = create(:calendar_event, program: program, start_time: date.next_week.beginning_of_week + 2.days, end_time: date.next_week.beginning_of_week + 2.days + 1.hour)

          get student_department_program_calendar_path(department, program), params: { filter: "date", view: "multi", date: date.to_s }
          expect(response.body).to include(event_this_week.title)
          expect(response.body).not_to include(event_next_week.title)
        end
      end

      it "uses current date when no date is provided" do
        get student_department_program_calendar_path(department, program), params: { filter: "date", view: "single" }
        expect(response).to have_http_status(:success)
      end

      it "uses first held_on_date when switching to date filter mode" do
        program.update!(held_on_dates: [Date.current.to_s, 1.week.from_now.to_date.to_s])
        get student_department_program_calendar_path(department, program), params: { filter: "date" }
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get student_department_program_calendar_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when not enrolled in program" do
      let(:other_student) { create(:user, :with_student_role) }

      before { sign_in_as(other_student) }

      it "redirects to dashboard with alert" do
        get student_department_program_calendar_path(department, program)
        expect(response).to redirect_to(student_dashboard_path)
        follow_redirect!
        expect(response.body).to include("not enrolled")
      end
    end
  end
end
