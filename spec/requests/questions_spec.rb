require 'rails_helper'

RSpec.describe "Questions", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }
  let(:question) { Question.create!(text: "Test Question", question_type: "text", questionnaire: questionnaire) }

  describe "GET /departments/:department_id/programs/:program_id/questionnaires/:questionnaire_id/questions/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_questionnaire_question_path(department, program, questionnaire)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_questionnaire_question_path(department, program, questionnaire)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/questionnaires/:questionnaire_id/questions" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a question" do
        expect {
          post department_program_questionnaire_questions_path(department, program, questionnaire), params: {
            question: { text: "New Question", question_type: "text", position: 1 }
          }
        }.to change { Question.count }.by(1)
        expect(response).to redirect_to(department_program_questionnaire_path(department, program, questionnaire))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_program_questionnaire_questions_path(department, program, questionnaire), params: {
          question: { text: "New Question", question_type: "text" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/questionnaires/:questionnaire_id/questions/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_questionnaire_question_path(department, program, questionnaire, question)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_questionnaire_question_path(department, program, questionnaire, question)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:program_id/questionnaires/:questionnaire_id/questions/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the question" do
        patch department_program_questionnaire_question_path(department, program, questionnaire, question), params: {
          question: { text: "Updated Question" }
        }
        expect(response).to redirect_to(department_program_questionnaire_path(department, program, questionnaire))
        expect(question.reload.text).to eq("Updated Question")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_questionnaire_question_path(department, program, questionnaire, question), params: {
          question: { text: "Updated Question" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/programs/:program_id/questionnaires/:questionnaire_id/questions/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the question" do
        question_to_delete = Question.create!(text: "To Delete", question_type: "text", questionnaire: questionnaire)
        expect {
          delete department_program_questionnaire_question_path(department, program, questionnaire, question_to_delete)
        }.to change { Question.count }.by(-1)
        expect(response).to redirect_to(department_program_questionnaire_path(department, program, questionnaire))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_questionnaire_question_path(department, program, questionnaire, question)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
