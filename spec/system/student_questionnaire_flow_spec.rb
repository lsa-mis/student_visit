require 'rails_helper'

RSpec.describe "Student Questionnaire Flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  let(:department) { create(:department, :with_active_program) }
  let(:program) { department.active_program }
  let(:student_user) { create(:user, :with_student_role, email_address: "student@example.com", password: "password123") }
  let!(:questionnaire) { create(:questionnaire, program: program, name: "Pre-Visit Questionnaire") }
  let!(:question1) { create(:question, questionnaire: questionnaire, text: "What are your goals for this visit?", question_type: "text") }
  let!(:question2) { create(:question, questionnaire: questionnaire, text: "Do you have any dietary restrictions?", question_type: "checkbox", options: [ "Vegetarian", "Vegan", "Gluten-free", "None" ]) }

  before do
    create(:student_program, user: student_user, program: program)
    questionnaire
    question1
    question2
  end

  it "allows student to view and fill out a questionnaire" do
    sign_in_as(student_user)
    visit student_department_program_questionnaires_path(department, program)
    expect(page).to have_current_path(student_department_program_questionnaires_path(department, program))
    expect(page).to have_content(questionnaire.name, wait: 5)
    within(:xpath, "//li[.//h3[contains(text(), '#{questionnaire.name}')]]") do
      click_link "View/Edit"
    end

    expect(current_path).to eq(student_department_program_questionnaire_path(department, program, questionnaire))
    expect(page).to have_content(question1.text, wait: 5)
    expect(page).to have_content(question2.text, wait: 5)
  end

  it "allows student to edit and save answers" do
    sign_in_as(student_user)
    visit edit_student_department_program_questionnaire_path(department, program, questionnaire)
    expect(page).to have_current_path(edit_student_department_program_questionnaire_path(department, program, questionnaire))
    # Fill in text answer - Rails converts answers[question_id][content] to answers_question_id_content
    field_id = "answers[#{question1.id}][content]"
    # Wait for the field to be present and fill it
    expect(page).to have_field(field_id)
    fill_in field_id, with: "I want to learn about research opportunities"

    # Wait for Save button and click it
    save_button = find_button("Save Answers", wait: 5)
    save_button.click

    # Wait for redirect - check we're on the show page
    expect(page).to have_content(questionnaire.name, wait: 5)
    answer = Answer.where(question: question1, student: student_user, program: program).first
    expect(answer).to be_present
    expect(answer.content.to_s).to include("research opportunities")
  end

  it "prevents editing after questionnaire due date" do
    program.update!(questionnaire_due_date: 1.day.ago)

    sign_in_as(student_user)
    visit edit_student_department_program_questionnaire_path(department, program, questionnaire)

    # Should show deadline message
    expect(page).to have_content("deadline has passed", wait: 5)
    # Button should not be present when due date passed
    expect(page).not_to have_button("Save Answers", wait: 2)
  end

  it "displays existing answers when viewing questionnaire" do
    answer = create(:answer, question: question1, student: student_user, program: program, content: "Existing answer")

    sign_in_as(student_user)
    visit student_department_program_questionnaire_path(department, program, questionnaire)

    # Wait for page to load and check for answer content
    expect(page).to have_content(question1.text, wait: 5)
    content_text = answer.content.respond_to?(:to_plain_text) ? answer.content.to_plain_text : answer.content.to_s
    expect(page).to have_content(content_text, wait: 5)
  end
end
