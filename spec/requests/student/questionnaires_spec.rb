require 'rails_helper'

RSpec.describe "Student::Questionnaires", type: :request do
  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role) }
  let(:questionnaire) { create(:questionnaire, program: program) }

  before do
    create(:student_program, user: student_user, program: program)
  end

  describe "GET /student/departments/:department_id/programs/:program_id/questionnaires" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get student_department_program_questionnaires_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays questionnaires for the program" do
        questionnaire1 = create(:questionnaire, program: program, name: "Questionnaire 1")
        questionnaire2 = create(:questionnaire, program: program, name: "Questionnaire 2")
        other_program = create(:program, department: department)
        other_questionnaire = create(:questionnaire, program: other_program)

        get student_department_program_questionnaires_path(department, program)
        expect(response.body).to include(questionnaire1.name)
        expect(response.body).to include(questionnaire2.name)
        expect(response.body).not_to include(other_questionnaire.name)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get student_department_program_questionnaires_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when not enrolled in program" do
      let(:other_student) { create(:user, :with_student_role) }

      before { sign_in_as(other_student) }

      it "redirects to dashboard with alert" do
        get student_department_program_questionnaires_path(department, program)
        expect(response).to redirect_to(student_dashboard_path)
        follow_redirect!
        expect(response.body).to include("not enrolled")
      end
    end
  end

  describe "GET /student/departments/:department_id/programs/:program_id/questionnaires/:id" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get student_department_program_questionnaire_path(department, program, questionnaire)
        expect(response).to have_http_status(:success)
      end

      it "displays the questionnaire" do
        get student_department_program_questionnaire_path(department, program, questionnaire)
        expect(response.body).to include(questionnaire.name)
      end

      it "displays questions" do
        question = create(:question, questionnaire: questionnaire, text: "Test Question")
        get student_department_program_questionnaire_path(department, program, questionnaire)
        expect(response.body).to include(question.text)
      end

      it "displays existing answers" do
        question = create(:question, questionnaire: questionnaire)
        answer = create(:answer, question: question, student: student_user, program: program, content: "My answer")
        get student_department_program_questionnaire_path(department, program, questionnaire)
        content_text = answer.content.respond_to?(:to_plain_text) ? answer.content.to_plain_text : answer.content.to_s
        expect(response.body).to include(content_text)
      end
    end
  end

  describe "GET /student/departments/:department_id/programs/:program_id/questionnaires/:id/edit" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get edit_student_department_program_questionnaire_path(department, program, questionnaire)
        expect(response).to have_http_status(:success)
      end

      it "displays the questionnaire form" do
        question = create(:question, questionnaire: questionnaire)
        get edit_student_department_program_questionnaire_path(department, program, questionnaire)
        expect(response.body).to include(question.text)
      end
    end
  end

  describe "PATCH /student/departments/:department_id/programs/:program_id/questionnaires/:id" do
    let(:question1) { create(:question, questionnaire: questionnaire, text: "Question 1") }
    let(:question2) { create(:question, questionnaire: questionnaire, text: "Question 2") }

    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "creates new answers" do
        patch student_department_program_questionnaire_path(department, program, questionnaire), params: {
          answers: {
            question1.id => { content: "Answer 1" },
            question2.id => { content: "Answer 2" }
          }
        }

        answer1 = Answer.where(question: question1, student: student_user, program: program).first
        answer2 = Answer.where(question: question2, student: student_user, program: program).first
        expect(answer1.content.to_s).to include("Answer 1")
        expect(answer2.content.to_s).to include("Answer 2")
      end

      it "updates existing answers" do
        answer = create(:answer, question: question1, student: student_user, program: program, content: "Old answer")

        patch student_department_program_questionnaire_path(department, program, questionnaire), params: {
          answers: {
            question1.id => { content: "New answer" }
          }
        }

        expect(answer.reload.content.to_s).to include("New answer")
      end

      it "redirects with success notice" do
        patch student_department_program_questionnaire_path(department, program, questionnaire), params: {
          answers: {
            question1.id => { content: "Answer 1" }
          }
        }

        expect(response).to redirect_to(student_department_program_questionnaire_path(department, program, questionnaire))
        # Flash is set before redirect
        expect(flash[:notice]).to include("saved")
      end

      it "prevents editing after questionnaire due date" do
        program.update!(questionnaire_due_date: 1.day.ago)

        patch student_department_program_questionnaire_path(department, program, questionnaire), params: {
          answers: {
            question1.id => { content: "Answer 1" }
          }
        }

        expect(response).to redirect_to(student_department_program_questionnaire_path(department, program, questionnaire))
        follow_redirect!
        expect(response.body).to include("deadline has passed")
      end

      it "ignores invalid question IDs" do
        invalid_id = 99999
        patch student_department_program_questionnaire_path(department, program, questionnaire), params: {
          answers: {
            invalid_id => { content: "Invalid answer" },
            question1.id => { content: "Valid answer" }
          }
        }

        expect(Answer.where(question_id: invalid_id).count).to eq(0)
        answer = Answer.where(question: question1, student: student_user, program: program).first
        expect(answer.content.to_s).to include("Valid answer")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch student_department_program_questionnaire_path(department, program, questionnaire), params: {
          answers: { question1.id => { content: "Answer" } }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
