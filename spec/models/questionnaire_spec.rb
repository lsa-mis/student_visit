require 'rails_helper'

RSpec.describe Questionnaire, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe 'associations' do
    subject { Questionnaire.new(name: "Test", program: program) }
    it { should belong_to(:program) }
    it { should have_many(:questions).dependent(:destroy) }
    it { should have_many(:answers).through(:questions) }
  end

  describe 'validations' do
    it 'requires name' do
      questionnaire = Questionnaire.new(program: program)
      expect(questionnaire).not_to be_valid
      expect(questionnaire.errors[:name]).to be_present
    end

    it 'is valid with name' do
      questionnaire = Questionnaire.new(name: "Test Questionnaire", program: program)
      expect(questionnaire).to be_valid
    end
  end

  describe 'questions association' do
    let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }

    it 'orders questions by position' do
      question1 = Question.create!(text: "Question 1", question_type: "text", questionnaire: questionnaire, position: 2)
      question2 = Question.create!(text: "Question 2", question_type: "text", questionnaire: questionnaire, position: 1)

      expect(questionnaire.questions.to_a).to eq([ question2, question1 ])
    end

    it 'destroys questions when questionnaire is destroyed' do
      question = Question.create!(text: "Test Question", question_type: "text", questionnaire: questionnaire)
      questionnaire.destroy
      expect(Question.find_by(id: question.id)).to be_nil
    end
  end

  describe 'answers association' do
    let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }
    let(:question) { Question.create!(text: "Test Question", question_type: "text", questionnaire: questionnaire) }
    let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }
    let!(:answer) { Answer.create!(question: question, student: student, program: program, content: "Answer") }

    it 'has access to answers' do
      expect(questionnaire.answers).to include(answer)
    end

    it 'destroys answers when questionnaire is destroyed' do
      questionnaire.destroy
      expect(Answer.find_by(id: answer.id)).to be_nil
    end
  end
end
