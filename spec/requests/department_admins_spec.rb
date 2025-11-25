require 'rails_helper'

RSpec.describe "DepartmentAdmins", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:user) { User.create!(email_address: 'admin@example.com', password: 'password123') }

  describe "GET /departments/:department_id/admins" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_admins_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_admins_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_admins_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/admins" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a department admin" do
        expect {
          post department_admins_path(department), params: {
            department_admin: { user_id: user.id }
          }
        }.to change { DepartmentAdmin.count }.by(1)
        expect(response).to redirect_to(department_admins_path(department))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_admins_path(department), params: {
          department_admin: { user_id: user.id }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/admins/:id" do
    let!(:department_admin) { DepartmentAdmin.create!(user: user, department: department) }

    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the department admin" do
        expect {
          delete department_admin_path(department, department_admin)
        }.to change { DepartmentAdmin.count }.by(-1)
        expect(response).to redirect_to(department_admins_path(department))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_admin_path(department, department_admin)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
