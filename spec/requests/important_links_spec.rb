require 'rails_helper'

RSpec.describe "ImportantLinks", type: :request do
  let(:department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:important_link) { create(:important_link, program: program) }

  describe "GET /departments/:department_id/programs/:program_id/important_links" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_important_links_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_important_links_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_important_links_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/important_links/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_important_link_path(department, program, important_link)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_important_link_path(department, program, important_link)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/important_links/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_important_link_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_important_link_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/important_links" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates an important link" do
        expect {
          post department_program_important_links_path(department, program), params: {
            important_link: { name: "Test Link", url: "https://example.com", ranking: 1 }
          }
        }.to change { ImportantLink.count }.by(1)
        expect(response).to redirect_to(department_program_important_link_path(department, program, ImportantLink.last))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_program_important_links_path(department, program), params: {
          important_link: { name: "Test Link", url: "https://example.com" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/important_links/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_important_link_path(department, program, important_link)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_important_link_path(department, program, important_link)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:program_id/important_links/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the important link" do
        patch department_program_important_link_path(department, program, important_link), params: {
          important_link: { name: "Updated Link" }
        }
        expect(response).to redirect_to(department_program_important_link_path(department, program, important_link))
        expect(important_link.reload.name).to eq("Updated Link")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_important_link_path(department, program, important_link), params: {
          important_link: { name: "Updated Link" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/programs/:program_id/important_links/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the important link" do
        link_to_delete = create(:important_link, program: program)
        expect {
          delete department_program_important_link_path(department, program, link_to_delete)
        }.to change { ImportantLink.count }.by(-1)
        expect(response).to redirect_to(department_program_important_links_path(department, program))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_important_link_path(department, program, important_link)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
