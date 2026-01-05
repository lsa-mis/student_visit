require 'rails_helper'

RSpec.describe "Vips", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }

  describe "GET /departments/:department_id/programs/:program_id/vips" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_vips_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_vips_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_vips_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/vips/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_vip_path(department, program, vip)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_vip_path(department, program, vip)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/vips/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_vip_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_vip_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/vips" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a vip" do
        expect {
          post department_program_vips_path(department, program), params: {
            vip: { name: "Dr. Jones" }
          }
        }.to change { Vip.count }.by(1)
        expect(response).to redirect_to(department_program_vip_path(department, program, Vip.last))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_program_vips_path(department, program), params: {
          vip: { name: "Dr. Jones" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/vips/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_vip_path(department, program, vip)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_vip_path(department, program, vip)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:program_id/vips/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the vip" do
        patch department_program_vip_path(department, program, vip), params: {
          vip: { name: "Dr. Updated" }
        }
        expect(response).to redirect_to(department_program_vip_path(department, program, vip))
        expect(vip.reload.name).to eq("Dr. Updated")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_vip_path(department, program, vip), params: {
          vip: { name: "Dr. Updated" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/programs/:program_id/vips/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the vip" do
        vip_to_delete = Vip.create!(name: "To Delete", program: program)
        expect {
          delete department_program_vip_path(department, program, vip_to_delete)
        }.to change { Vip.count }.by(-1)
        expect(response).to redirect_to(department_program_vips_path(department, program))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_vip_path(department, program, vip)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/vips/bulk_upload" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get bulk_upload_department_program_vips_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get bulk_upload_department_program_vips_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
