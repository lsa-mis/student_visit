require 'rails_helper'

RSpec.describe "Students", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe "GET /departments/:department_id/programs/:program_id/students" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_students_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "shows bulk upload and actions" do
        student_user = User.create!(email_address: "student@example.com", password: "password123")
        student_user.add_role("student")
        StudentProgram.create!(user: student_user, program: program)

        get department_program_students_path(department, program)
        bulk_upload_path = bulk_upload_department_program_students_path(department, program)
        # Assert against the actual Bulk Upload anchor, not the page-instructions text.
        expect(response.body).to match(/href=["']#{Regexp.escape(bulk_upload_path)}["'][^>]*>\s*Bulk Upload\s*</)
        expect(response.body).to include("Actions")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_students_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_students_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/students" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "re-renders index with admin controls on validation error" do
        post department_program_students_path(department, program), params: {
          email_address: "" # missing email triggers validation branch
        }

        expect(response).to have_http_status(:unprocessable_content)
        bulk_upload_path = bulk_upload_department_program_students_path(department, program)
        expect(response).to show_action_element(/href=["']#{Regexp.escape(bulk_upload_path)}["']/)
        expect(response).to show_action_element("Add Student")
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/students/export" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns CSV attachment" do
        get export_department_program_students_path(department, program, format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.body).to include("Email")
        expect(response.body).to include("Last Name")
        expect(response.body).to include("First Name")
        expect(response.body).to include("UMID")
        expect(response.body).to include("Enrolled")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get export_department_program_students_path(department, program, format: :csv)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/students/bulk_upload" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get bulk_upload_department_program_students_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get bulk_upload_department_program_students_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
