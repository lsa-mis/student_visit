require 'rails_helper'

RSpec.describe "AffiliatedResources", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:affiliated_resource) { AffiliatedResource.create!(name: "Test Resource", url: "http://example.com", department: department) }

  describe "GET /departments/:department_id/affiliated_resources" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_affiliated_resources_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_affiliated_resources_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_affiliated_resources_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/affiliated_resources/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_affiliated_resource_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_affiliated_resource_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/affiliated_resources" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates an affiliated resource" do
        expect {
          post department_affiliated_resources_path(department), params: {
            affiliated_resource: { name: "New Resource", url: "http://new.com" }
          }
        }.to change { AffiliatedResource.count }.by(1)
        expect(response).to redirect_to(department_affiliated_resource_path(department, AffiliatedResource.last))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_affiliated_resources_path(department), params: {
          affiliated_resource: { name: "New Resource", url: "http://new.com" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/affiliated_resources/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_affiliated_resource_path(department, affiliated_resource)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_affiliated_resource_path(department, affiliated_resource)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/affiliated_resources/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the affiliated resource" do
        patch department_affiliated_resource_path(department, affiliated_resource), params: {
          affiliated_resource: { name: "Updated Resource" }
        }
        expect(response).to redirect_to(department_affiliated_resource_path(department, affiliated_resource))
        expect(affiliated_resource.reload.name).to eq("Updated Resource")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_affiliated_resource_path(department, affiliated_resource), params: {
          affiliated_resource: { name: "Updated Resource" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/affiliated_resources/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the affiliated resource" do
        resource_to_delete = AffiliatedResource.create!(name: "To Delete", url: "http://delete.com", department: department)
        expect {
          delete department_affiliated_resource_path(department, resource_to_delete)
        }.to change { AffiliatedResource.count }.by(-1)
        expect(response).to redirect_to(department_affiliated_resources_path(department))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_affiliated_resource_path(department, affiliated_resource)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
