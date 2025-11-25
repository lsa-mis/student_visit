require 'rails_helper'

RSpec.describe DepartmentAdmin, type: :model do
  let(:user) { User.create!(email_address: 'admin@example.com', password: 'password123') }
  let(:department) { Department.create!(name: "Test Department") }

  describe 'associations' do
    subject { DepartmentAdmin.new(user: user, department: department) }
    it { should belong_to(:user) }
    it { should belong_to(:department) }
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to department_id' do
      DepartmentAdmin.create!(user: user, department: department)
      duplicate = DepartmentAdmin.new(user: user, department: department)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows same user with different departments' do
      DepartmentAdmin.create!(user: user, department: department)
      other_department = Department.create!(name: "Other Department")
      other_admin = DepartmentAdmin.new(user: user, department: other_department)
      expect(other_admin).to be_valid
    end

    it 'allows same department with different users' do
      DepartmentAdmin.create!(user: user, department: department)
      other_user = User.create!(email_address: 'other@example.com', password: 'password123')
      other_admin = DepartmentAdmin.new(user: other_user, department: department)
      expect(other_admin).to be_valid
    end
  end
end
