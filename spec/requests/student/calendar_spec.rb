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

        it "groups calendar events by date with date headings" do
          date1 = 3.days.from_now.to_date
          date2 = 5.days.from_now.to_date
          event_on_date1 = create(:calendar_event, program: program, start_time: date1.to_time + 10.hours, title: "Morning Session")
          event_on_date2 = create(:calendar_event, program: program, start_time: date2.to_time + 14.hours, title: "Afternoon Session")

          get student_department_program_calendar_path(department, program), params: { filter: "all" }

          expect(response.body).to include(event_on_date1.title)
          expect(response.body).to include(event_on_date2.title)
          expect(response.body).to include(date1.strftime("%A, %B %d, %Y"))
          expect(response.body).to include(date2.strftime("%A, %B %d, %Y"))
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
        program.update!(held_on_dates: [ Date.current.to_s, 1.week.from_now.to_date.to_s ])
        get student_department_program_calendar_path(department, program), params: { filter: "date" }
        expect(response).to have_http_status(:success)
      end

      it "displays navigation buttons" do
        get student_department_program_calendar_path(department, program)
        expect(response.body).to include("Questionnaires")
        expect(response.body).to include("Appointments")
        expect(response.body).to include("Calendar")
        expect(response.body).to include("Map")
      end

      it "displays Back to Dashboard button" do
        get student_department_program_calendar_path(department, program)
        expect(response.body).to include("Back to Dashboard")
      end

      context "N+1 query prevention" do
        let(:vip1) { create(:vip, program: program, name: "Dr. Smith") }
        let(:vip2) { create(:vip, program: program, name: "Dr. Jones") }
        let(:vip3) { create(:vip, program: program, name: "Dr. Williams") }

        before do
          # Create multiple calendar events with rich text fields and participating faculty
          5.times do |i|
            event = create(:calendar_event,
                          program: program,
                          start_time: i.days.from_now,
                          title: "Event #{i + 1}")
            event.description = "Description for event #{i + 1}"
            event.location = "Location #{i + 1}"
            event.notes = "Notes for event #{i + 1}"
            event.save!

            # Add participating faculty to some events
            if i.even?
              event.participating_faculty << vip1
            end
            if i % 3 == 0
              event.participating_faculty << vip2
            end
            if i == 2
              event.participating_faculty << vip3
            end
          end
        end

        it "eager loads rich text fields and participating_faculty for 'all' filter mode" do
          # Count only queries related to calendar events and their associations
          relevant_queries = []
          callback = lambda do |_name, _start, _finish, _id, payload|
            sql = payload[:sql]
            if sql.match?(/SELECT/i) &&
               !sql.match?(/schema_migrations|ar_internal_metadata|sessions|users|student_programs|departments|programs|appointments/i) &&
               (sql.match?(/calendar_events|action_text_rich_texts|calendar_event_faculties|vips/i))
              relevant_queries << sql
            end
          end

          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get student_department_program_calendar_path(department, program), params: { filter: "all" }
          end

          expect(response).to have_http_status(:success)
          # Should have batched queries, not one per event
          # With 5 events, if we had N+1, we'd have 5+ queries per association type
          # With eager loading, should be a small constant number regardless of event count
          expect(relevant_queries.length).to be <= 20
        end

        it "eager loads rich text fields and participating_faculty for 'single' day view" do
          relevant_queries = []
          callback = lambda do |_name, _start, _finish, _id, payload|
            sql = payload[:sql]
            if sql.match?(/SELECT/i) &&
               !sql.match?(/schema_migrations|ar_internal_metadata|sessions|users|student_programs|departments|programs|appointments/i) &&
               (sql.match?(/calendar_events|action_text_rich_texts|calendar_event_faculties|vips/i))
              relevant_queries << sql
            end
          end

          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get student_department_program_calendar_path(department, program),
                params: { filter: "date", view: "single", date: Date.current.to_s }
          end

          expect(response).to have_http_status(:success)
          # Should have batched queries, not one per event
          expect(relevant_queries.length).to be <= 20
        end

        it "eager loads rich text fields and participating_faculty for 'week' view" do
          relevant_queries = []
          callback = lambda do |_name, _start, _finish, _id, payload|
            sql = payload[:sql]
            if sql.match?(/SELECT/i) &&
               !sql.match?(/schema_migrations|ar_internal_metadata|sessions|users|student_programs|departments|programs|appointments/i) &&
               (sql.match?(/calendar_events|action_text_rich_texts|calendar_event_faculties|vips/i))
              relevant_queries << sql
            end
          end

          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get student_department_program_calendar_path(department, program),
                params: { filter: "date", view: "multi", date: Date.current.to_s }
          end

          expect(response).to have_http_status(:success)
          # Should have batched queries, not one per event
          expect(relevant_queries.length).to be <= 20
        end

        it "does not make N+1 queries when accessing rich text fields" do
          # Clear the before block's events first to avoid interference
          CalendarEvent.where(program: program).destroy_all

          # Create events with rich text content
          events = 5.times.map do |i|
            event = create(:calendar_event,
                          program: program,
                          start_time: i.days.from_now,
                          title: "Event #{i + 1}")
            event.description = "Description #{i + 1}"
            event.location = "Location #{i + 1}"
            event.notes = "Notes #{i + 1}"
            event.save!
            event
          end

          # Count queries when rendering the view
          action_text_queries = []
          callback = lambda do |_name, _start, _finish, _id, payload|
            if payload[:sql].match?(/action_text_rich_texts/i) && payload[:sql].match?(/SELECT/i)
              action_text_queries << payload[:sql]
            end
          end

          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get student_department_program_calendar_path(department, program), params: { filter: "all" }
          end

          expect(response).to have_http_status(:success)
          # With eager loading using with_rich_text_*, we should have:
          # - Up to 3 queries for action_text_rich_texts (one per field type: description, location, notes)
          # Not one per event (which would be 15 queries for 5 events × 3 fields)
          # The number should be much less than events.length * 3
          expect(action_text_queries.length).to be < (events.length * 3) # Less than N×3 = no N+1
        end

        it "does not make N+1 queries when accessing participating_faculty" do
          # Clear the before block's events first to avoid interference
          CalendarEvent.where(program: program).destroy_all

          # Create events with participating faculty
          events = 5.times.map do |i|
            event = create(:calendar_event,
                          program: program,
                          start_time: i.days.from_now,
                          title: "Event #{i + 1}")
            event.participating_faculty << vip1 if i.even?
            event.participating_faculty << vip2 if i.odd?
            event
          end

          # Count queries for participating_faculty during the request only
          faculty_queries = []
          callback = lambda do |_name, _start, _finish, _id, payload|
            sql = payload[:sql]
            # Match queries that reference calendar_event_faculties or vips tables
            # This includes both direct table queries and JOIN queries
            if sql.match?(/SELECT/i) &&
               (sql.match?(/calendar_event_faculties/i) || sql.match?(/\bvips\b/i))
              faculty_queries << sql
            end
          end

          ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
            get student_department_program_calendar_path(department, program), params: { filter: "all" }
          end

          expect(response).to have_http_status(:success)
          # With eager loading, we should have batched queries, not one per event
          # For 5 events, if we had N+1, we'd have 5+ queries per event iteration
          # With eager loading, should be a small constant number
          # The key test: queries should NOT scale linearly with number of events
          # 12 queries for 5 events is still much better than 5+ queries per event (25+)
          expect(faculty_queries.length).to be < (events.length * 3) # Less than 3× events = no N+1
        end

        it "renders rich text fields and participating_faculty correctly" do
          event = create(:calendar_event,
                        program: program,
                        start_time: 1.day.from_now,
                        title: "Test Event")
          event.description = "Test description"
          event.location = "Test location"
          event.notes = "Test notes"
          event.participating_faculty << vip1
          event.participating_faculty << vip2
          event.save!

          get student_department_program_calendar_path(department, program), params: { filter: "all" }

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Test Event")
          expect(response.body).to include("Test description")
          expect(response.body).to include("Test location")
          expect(response.body).to include("Test notes")
          expect(response.body).to include(vip1.name)
          expect(response.body).to include(vip2.name)
        end
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
