require 'rails_helper'

RSpec.describe Question, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }
  let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }

  describe 'associations' do
    subject { Question.new(text: "Test", question_type: "text", questionnaire: questionnaire) }
    it { should belong_to(:questionnaire) }
    it { should have_many(:answers).dependent(:destroy) }
  end

  describe 'validations' do
    it 'requires text' do
      question = Question.new(question_type: "text", questionnaire: questionnaire)
      expect(question).not_to be_valid
      expect(question.errors[:text]).to be_present
    end

    it 'requires question_type' do
      question = Question.new(text: "Test Question", questionnaire: questionnaire)
      expect(question).not_to be_valid
      expect(question.errors[:question_type]).to be_present
    end

    it 'validates question_type inclusion' do
      question = Question.new(text: "Test Question", question_type: "invalid", questionnaire: questionnaire)
      expect(question).not_to be_valid
      expect(question.errors[:question_type]).to be_present
    end

    Question::QUESTION_TYPES.each do |type|
      it "allows question_type '#{type}'" do
        question = Question.new(text: "Test Question", question_type: type, questionnaire: questionnaire)
        expect(question).to be_valid
      end
    end

    it 'is valid with proper attributes' do
      question = Question.new(text: "Test Question", question_type: "text", questionnaire: questionnaire)
      expect(question).to be_valid
    end
  end

  describe 'QUESTION_TYPES constant' do
    it 'defines valid question types' do
      expect(Question::QUESTION_TYPES).to include('text', 'rich_text', 'checkbox', 'radio', 'datetime', 'link')
    end
  end

  describe 'options serialization' do
    it 'serializes array options' do
      question = Question.create!(
        text: "Test Question",
        question_type: "radio",
        questionnaire: questionnaire,
        options: [ "Option 1", "Option 2", "Option 3" ]
      )
      expect(question.reload.options).to eq([ "Option 1", "Option 2", "Option 3" ])
    end

    it 'serializes hash options' do
      question = Question.create!(
        text: "Test Question",
        question_type: "checkbox",
        questionnaire: questionnaire,
        options: { "key1" => "value1", "key2" => "value2" }
      )
      expect(question.reload.options).to eq({ "key1" => "value1", "key2" => "value2" })
    end
  end

  describe '#options_array' do
    it 'returns options when options is an array' do
      question = Question.new(options: [ "Option 1", "Option 2" ])
      expect(question.options_array).to eq([ "Option 1", "Option 2" ])
    end

    it 'returns empty array when options is not an array' do
      question = Question.new(options: { "key" => "value" })
      expect(question.options_array).to eq([])
    end

    it 'returns empty array when options is nil' do
      question = Question.new(options: nil)
      expect(question.options_array).to eq([])
    end
  end

  describe '#options_hash' do
    it 'returns options when options is a hash' do
      question = Question.new(options: { "key" => "value" })
      expect(question.options_hash).to eq({ "key" => "value" })
    end

    it 'returns empty hash when options is not a hash' do
      question = Question.new(options: [ "Option 1" ])
      expect(question.options_hash).to eq({})
    end

    it 'returns empty hash when options is nil' do
      question = Question.new(options: nil)
      expect(question.options_hash).to eq({})
    end
  end

  describe 'answers association' do
    let(:question) { Question.create!(text: "Test Question", question_type: "text", questionnaire: questionnaire) }
    let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }
    let!(:answer) { Answer.create!(question: question, student: student, program: program, content: "Answer") }

    it 'has access to answers' do
      expect(question.answers).to include(answer)
    end

    it 'destroys answers when question is destroyed' do
      question.destroy
      expect(Answer.find_by(id: answer.id)).to be_nil
    end
  end
end
