require 'rails_helper'

RSpec.describe "Questionnaires", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:other_department) { Department.create!(name: "Other Department") }
  let(:other_program) { Program.create!(name: "Other Program", department: other_department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }
  let(:other_questionnaire) { Questionnaire.create!(name: "Other Test Questionnaire", program: other_program) }

  describe "GET /departments/:department_id/programs/:program_id/questionnaires" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_questionnaires_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "shows questionnaire actions" do
        questionnaire
        get department_program_questionnaires_path(department, program)
        expect(response.body).to include("View Responses")
        expect(response.body).to include("Edit")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "shows questionnaire actions" do
        questionnaire
        get department_program_questionnaires_path(department, program)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("View Responses")
        expect(response.body).to include("Edit")
      end
    end

    context "when authenticated as department admin of this department" do
      before { sign_in_as_department_admin(department) }

      it "denies access to other-department program questionnaires" do
        other_questionnaire
        get department_program_questionnaires_path(other_department, other_program)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_questionnaires_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/questionnaires/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_questionnaire_path(department, program, questionnaire)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_questionnaire_path(department, program, questionnaire)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/questionnaires/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_questionnaire_path(department, program, questionnaire)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_questionnaire_path(department, program, questionnaire)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:program_id/questionnaires/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the questionnaire" do
        patch department_program_questionnaire_path(department, program, questionnaire), params: {
          questionnaire: { name: "Updated Questionnaire" }
        }
        expect(response).to redirect_to(department_program_questionnaire_path(department, program, questionnaire))
        expect(questionnaire.reload.name).to eq("Updated Questionnaire")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_questionnaire_path(department, program, questionnaire), params: {
          questionnaire: { name: "Updated Questionnaire" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
