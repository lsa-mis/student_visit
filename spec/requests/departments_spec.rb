require 'rails_helper'

RSpec.describe "Departments", type: :request do
  let(:department) { Department.create!(name: "Test Department") }

  describe "GET /departments" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get departments_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get departments_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get departments_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a department" do
        expect {
          post departments_path, params: { department: { name: "New Department" } }
        }.to change { Department.count }.by(1)
        expect(response).to redirect_to(department_path(Department.last))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post departments_path, params: { department: { name: "New Department" } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the department" do
        patch department_path(department), params: { department: { name: "Updated Department" } }
        expect(response).to redirect_to(department_path(department))
        expect(department.reload.name).to eq("Updated Department")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_path(department), params: { department: { name: "Updated Department" } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the department" do
        department_to_delete = Department.create!(name: "To Delete")
        expect {
          delete department_path(department_to_delete)
        }.to change { Department.count }.by(-1)
        expect(response).to redirect_to(departments_path)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
