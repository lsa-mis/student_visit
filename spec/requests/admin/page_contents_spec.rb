require 'rails_helper'

RSpec.describe "Admin::PageContents", type: :request do
  describe "GET /admin/page_contents" do
    let!(:page_content1) { create(:page_content, page_path: "/test1", area_name: "main") }
    let!(:page_content2) { create(:page_content, page_path: "/test2", area_name: "sidebar") }

    context "as super admin" do
      before { sign_in_as_super_admin }

      it "allows access" do
        get admin_page_contents_path
        expect(response).to have_http_status(:success)
      end

      it "displays all page contents" do
        get admin_page_contents_path
        expect(response.body).to include(page_content1.page_path)
        expect(response.body).to include(page_content2.page_path)
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        get admin_page_contents_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "as student" do
      before { sign_in_as_student }

      it "denies access" do
        get admin_page_contents_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "as unauthenticated user" do
      it "redirects to login" do
        get admin_page_contents_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/page_contents/:id" do
    let!(:page_content) { create(:page_content) }

    context "as super admin" do
      before { sign_in_as_super_admin }

      it "allows access" do
        get admin_page_content_path(page_content)
        expect(response).to have_http_status(:success)
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        get admin_page_content_path(page_content)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/page_contents/new" do
    context "as super admin" do
      before { sign_in_as_super_admin }

      it "allows access" do
        get new_admin_page_content_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        get new_admin_page_content_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /admin/page_contents" do
    let(:valid_params) do
      { page_content: { page_path: "/new-page", area_name: "main", content: "New content" } }
    end

    context "as super admin" do
      before { sign_in_as_super_admin }

      it "creates a new page content" do
        expect {
          post admin_page_contents_path, params: valid_params
        }.to change { PageContent.count }.by(1)
      end

      it "redirects to index with notice" do
        post admin_page_contents_path, params: valid_params
        expect(response).to redirect_to(admin_page_contents_path)
        expect(flash[:notice]).to be_present
      end

      it "renders new with errors when invalid" do
        invalid_params = { page_content: { page_path: "", area_name: "" } }
        post admin_page_contents_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("error") # Check for error messages in response
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        post admin_page_contents_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/page_contents/:id/edit" do
    let!(:page_content) { create(:page_content) }

    context "as super admin" do
      before { sign_in_as_super_admin }

      it "allows access" do
        get edit_admin_page_content_path(page_content)
        expect(response).to have_http_status(:success)
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        get edit_admin_page_content_path(page_content)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/page_contents/:id" do
    let!(:page_content) { create(:page_content, content: "Original content") }

    context "as super admin" do
      before { sign_in_as_super_admin }

      it "updates the page content" do
        patch admin_page_content_path(page_content), params: {
          page_content: { content: "Updated content" }
        }
        page_content.reload
        expect(page_content.content.to_plain_text.strip).to eq("Updated content")
      end

      it "redirects to index with notice" do
        patch admin_page_content_path(page_content), params: {
          page_content: { content: "Updated content" }
        }
        expect(response).to redirect_to(admin_page_contents_path)
        expect(flash[:notice]).to be_present
      end

      it "renders edit with errors when invalid" do
        patch admin_page_content_path(page_content), params: {
          page_content: { page_path: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("error") # Check for error messages in response
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        patch admin_page_content_path(page_content), params: {
          page_content: { content: "Updated content" }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /admin/page_contents/:id" do
    let!(:page_content) { create(:page_content) }

    context "as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the page content" do
        expect {
          delete admin_page_content_path(page_content)
        }.to change { PageContent.count }.by(-1)
      end

      it "redirects to index with notice" do
        delete admin_page_content_path(page_content)
        expect(response).to redirect_to(admin_page_contents_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "as department admin" do
      before { sign_in_as_department_admin }

      it "denies access" do
        delete admin_page_content_path(page_content)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
