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

      it "displays the department address information" do
        get student_department_map_path(department)
        expect(response.body).to include(department.street_address) if department.street_address.present?
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get student_department_map_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as non-student" do
      before { sign_in_as_super_admin }

      it "denies access" do
        get student_department_map_path(department)
        expect(response).to have_http_status(:forbidden).or have_http_status(:redirect)
      end
    end
  end
end
