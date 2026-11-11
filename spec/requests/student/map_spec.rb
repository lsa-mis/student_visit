require 'rails_helper'

RSpec.describe "Student::Map", type: :request do
  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role) }

  before do
    create(:student_program, user: student_user, program: program)
  end

  describe "GET /student/departments/:department_id/map" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get student_department_map_path(department)
        expect(response).to have_http_status(:success)
      end

      it "displays the department information" do
        get student_department_map_path(department)
        expect(response.body).to include(department.name)
      end

      it "marks the department inline link as underlined (LRA-1417)" do
        get student_department_map_path(department)
        expect(response.body).to match(
          /href="#{Regexp.escape(student_dashboard_path)}"[^>]*class="[^"]*\bunderline\b/
        )
      end

      it "preserves Create your own link text when embed HTML is stored (LRA-1417)" do
        program.update!(
          google_map_url: <<~HTML.squish
            <iframe src="https://www.google.com/maps/d/embed?mid=abc123" width="640" height="480"></iframe>
            <br /><a href="//support.google.com/mymaps/answer/3024454?hl=en&ref_topic=3188329" target="_blank">Create your own.</a>
          HTML
        )

        get student_department_map_path(department)

        # Stimulus data attribute carries the embed; JS renders the attribution link client-side.
        expect(response.body).to include("support.google.com/mymaps/answer/3024454")
        expect(response.body).to include("Create your own.")
        expect(response.body).to include("maps/d/embed?mid=abc123")
      end

      it "displays the department address information" do
        get student_department_map_path(department)
        expect(response.body).to include(department.street_address) if department.street_address.present?
      end

      it "displays navigation buttons" do
        get student_department_map_path(department)
        expect(response.body).to include("Questionnaires")
        expect(response.body).to include("Appointments")
        expect(response.body).to include("Calendar")
        expect(response.body).to include("Map")
      end

      it "displays Back to Dashboard button" do
        get student_department_map_path(department)
        expect(response.body).to include("Back to Dashboard")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get student_department_map_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as non-student (admin preview)" do
      before { sign_in_as_super_admin }

      it "allows access" do
        get student_department_map_path(department)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(department.name)
      end
    end
  end
end
