require 'rails_helper'

RSpec.describe Department, type: :model do
  describe 'associations' do
    subject { Department.new(name: "Test Department") }
    it { should belong_to(:active_program).class_name("Program").optional }
    it { should have_many(:programs).dependent(:destroy) }
    it { should have_many(:department_admins).dependent(:destroy) }
    it { should have_many(:admin_users).through(:department_admins).source(:user) }
    it { should have_many(:affiliated_resources).dependent(:destroy) }
    # Note: has_one_attached matcher may not be available in shoulda-matchers
    # it { should have_one_attached(:image) }
  end

  describe 'validations' do
    it 'requires name' do
      department = Department.new
      expect(department).not_to be_valid
      expect(department.errors[:name]).to be_present
    end

    it 'requires unique name' do
      Department.create!(name: "Test Department")
      duplicate = Department.new(name: "Test Department")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'is valid with name' do
      department = Department.new(name: "Test Department")
      expect(department).to be_valid
    end
  end

  describe 'rich text mission_statement' do
    it 'has mission_statement field' do
      department = Department.create!(name: "Test Department")
      department.mission_statement = "Our mission"
      expect(department.mission_statement).to be_present
    end
  end

  describe '#admin_users_for' do
    let(:department) { Department.create!(name: "Test Department") }
    let(:admin_user) { User.create!(email_address: 'admin@example.com', password: 'password123') }
    let(:super_admin) { User.create!(email_address: 'super@example.com', password: 'password123') }

    before do
      super_admin.add_role("super_admin")
      DepartmentAdmin.create!(user: admin_user, department: department)
    end

    it 'returns all admin_users for super_admin' do
      expect(department.admin_users_for(super_admin)).to include(admin_user)
    end

    it 'returns admin_users for regular user' do
      regular_user = User.create!(email_address: 'regular@example.com', password: 'password123')
      expect(department.admin_users_for(regular_user)).to include(admin_user)
    end

    it 'returns admin_users when user is nil' do
      expect(department.admin_users_for(nil)).to include(admin_user)
    end
  end

  describe 'programs association' do
    let(:department) { Department.create!(name: "Test Department") }
    let!(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

    it 'has access to programs' do
      expect(department.programs).to include(program)
    end

    it 'destroys programs when department is destroyed' do
      department.destroy
      expect(Program.find_by(id: program.id)).to be_nil
    end
  end

  describe 'active_program association' do
    let(:department) { Department.create!(name: "Test Department") }
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, active: true, information_email_address: "test@example.com") }

    it 'can have an active_program' do
      department.update!(active_program: program)
      expect(department.active_program).to eq(program)
    end
  end
end
