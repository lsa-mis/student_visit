require 'rails_helper'

RSpec.describe StudentProgram, type: :model do
  let(:user) { User.create!(email_address: 'student@example.com', password: 'password123') }
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe 'associations' do
    subject { StudentProgram.new(user: user, program: program) }
    it { should belong_to(:user) }
    it { should belong_to(:program) }
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to program_id' do
      StudentProgram.create!(user: user, program: program)
      duplicate = StudentProgram.new(user: user, program: program)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows same user with different programs' do
      StudentProgram.create!(user: user, program: program)
      other_program = Program.create!(name: "Other Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com")
      other_enrollment = StudentProgram.new(user: user, program: other_program)
      expect(other_enrollment).to be_valid
    end

    it 'allows same program with different users' do
      StudentProgram.create!(user: user, program: program)
      other_user = User.create!(email_address: 'other@example.com', password: 'password123')
      other_enrollment = StudentProgram.new(user: other_user, program: program)
      expect(other_enrollment).to be_valid
    end
  end
end
