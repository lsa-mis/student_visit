require 'rails_helper'

RSpec.describe AnswerEdit, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }
  let(:question) { Question.create!(text: "Test Question", question_type: "text", questionnaire: questionnaire) }
  let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }
  let(:answer) { Answer.create!(question: question, student: student, program: program, content: "Original") }
  let(:editor) { User.create!(email_address: 'editor@example.com', password: 'password123') }

  describe 'associations' do
    subject { AnswerEdit.new(answer: answer, edited_by: editor, edited_at: Time.current) }
    it { should belong_to(:answer) }
    it { should belong_to(:edited_by).class_name("User") }
  end

  describe 'validations' do
    it 'requires edited_at' do
      edit = AnswerEdit.new(answer: answer, edited_by: editor)
      expect(edit).not_to be_valid
      expect(edit.errors[:edited_at]).to be_present
    end

    it 'is valid with edited_at' do
      edit = AnswerEdit.new(answer: answer, edited_by: editor, edited_at: Time.current)
      expect(edit).to be_valid
    end
  end
end
