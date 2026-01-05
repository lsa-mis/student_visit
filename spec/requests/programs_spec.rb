require 'rails_helper'

RSpec.describe "Programs", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe "GET /departments/:department_id/programs" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_programs_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_programs_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_programs_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a program" do
        expect {
          post department_programs_path(department), params: {
            program: { name: "New Program", default_appointment_length: 30, information_email_address: "new@example.com" }
          }
        }.to change { Program.count }.by(1)
        expect(response).to redirect_to(department_program_path(department, Program.last))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_programs_path(department), params: {
          program: { name: "New Program", default_appointment_length: 30 }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the program" do
        patch department_program_path(department, program), params: {
          program: { name: "Updated Program" }
        }
        expect(response).to redirect_to(department_program_path(department, program))
        expect(program.reload.name).to eq("Updated Program")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_path(department, program), params: {
          program: { name: "Updated Program" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/programs/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the program" do
        program_to_delete = Program.create!(name: "To Delete", department: department, default_appointment_length: 30, information_email_address: "test@example.com")
        expect {
          delete department_program_path(department, program_to_delete)
        }.to change { Program.count }.by(-1)
        expect(response).to redirect_to(department_programs_path(department))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
