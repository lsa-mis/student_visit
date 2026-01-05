require 'rails_helper'

RSpec.describe "CalendarEvents", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:calendar_event) do
    CalendarEvent.create!(
      title: "Test Event",
      start_time: Time.current,
      end_time: 1.hour.from_now,
      program: program
    )
  end

  describe "GET /departments/:department_id/programs/:program_id/calendar_events" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_calendar_events_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_calendar_events_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_calendar_events_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/calendar_events/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_calendar_event_path(department, program, calendar_event)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_calendar_event_path(department, program, calendar_event)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/calendar_events/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_calendar_event_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_calendar_event_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/calendar_events" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a calendar event" do
        expect {
          post department_program_calendar_events_path(department, program), params: {
            calendar_event: {
              title: "New Event",
              start_time: 1.hour.from_now,
              end_time: 2.hours.from_now
            }
          }
        }.to change { CalendarEvent.count }.by(1)
        expect(response).to redirect_to(department_program_calendar_events_path(department, program))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_program_calendar_events_path(department, program), params: {
          calendar_event: {
            title: "New Event",
            start_time: 1.hour.from_now,
            end_time: 2.hours.from_now
          }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/calendar_events/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_calendar_event_path(department, program, calendar_event)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_calendar_event_path(department, program, calendar_event)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:program_id/calendar_events/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the calendar event" do
        patch department_program_calendar_event_path(department, program, calendar_event), params: {
          calendar_event: { title: "Updated Event" }
        }
        expect(response).to redirect_to(department_program_calendar_event_path(department, program, calendar_event))
        expect(calendar_event.reload.title).to eq("Updated Event")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_calendar_event_path(department, program, calendar_event), params: {
          calendar_event: { title: "Updated Event" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/programs/:program_id/calendar_events/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the calendar event" do
        event_to_delete = CalendarEvent.create!(
          title: "To Delete",
          start_time: Time.current,
          end_time: 1.hour.from_now,
          program: program
        )
        expect {
          delete department_program_calendar_event_path(department, program, event_to_delete)
        }.to change { CalendarEvent.count }.by(-1)
        expect(response).to redirect_to(department_program_calendar_events_path(department, program))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_calendar_event_path(department, program, calendar_event)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
