require 'rails_helper'

RSpec.describe "Admin::Reports", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe "GET /admin/departments/:department_id/programs/:program_id/reports/students" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get students_admin_department_program_reports_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get students_admin_department_program_reports_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get students_admin_department_program_reports_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/departments/:department_id/programs/:program_id/reports/appointments" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get appointments_admin_department_program_reports_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get appointments_admin_department_program_reports_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get appointments_admin_department_program_reports_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/departments/:department_id/programs/:program_id/reports/calendar" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get calendar_admin_department_program_reports_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get calendar_admin_department_program_reports_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get calendar_admin_department_program_reports_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
