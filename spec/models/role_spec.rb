require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    subject { Role.new(name: "test_role") }
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:users).through(:user_roles) }
  end

  describe 'validations' do
    it 'requires name' do
      role = Role.new
      expect(role).not_to be_valid
      expect(role.errors[:name]).to be_present
    end

    it 'requires unique name' do
      Role.create!(name: "test_role")
      duplicate = Role.new(name: "test_role")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'is valid with name' do
      role = Role.new(name: "test_role")
      expect(role).to be_valid
    end
  end

  describe 'ROLE_TYPES constant' do
    it 'defines valid role types' do
      expect(Role::ROLE_TYPES).to include('super_admin', 'department_admin', 'student', 'faculty')
    end
  end

  describe 'class methods for role types' do
    Role::ROLE_TYPES.each do |role_type|
      describe ".#{role_type}" do
        it "finds or creates #{role_type} role" do
          role = Role.send(role_type)
          expect(role).to be_persisted
          expect(role.name).to eq(role_type)
        end

        it "returns existing #{role_type} role if it exists" do
          existing_role = Role.create!(name: role_type)
          role = Role.send(role_type)
          expect(role.id).to eq(existing_role.id)
        end
      end
    end
  end

  describe 'user_roles association' do
    let(:role) { Role.create!(name: "test_role") }
    let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }
    let!(:user_role) { UserRole.create!(user: user, role: role) }

    it 'has access to user_roles' do
      expect(role.user_roles).to include(user_role)
    end

    it 'destroys user_roles when role is destroyed' do
      role.destroy
      expect(UserRole.find_by(id: user_role.id)).to be_nil
    end
  end

  describe 'users association' do
    let(:role) { Role.create!(name: "test_role") }
    let(:user1) { User.create!(email_address: 'user1@example.com', password: 'password123') }
    let(:user2) { User.create!(email_address: 'user2@example.com', password: 'password123') }

    before do
      UserRole.create!(user: user1, role: role)
      UserRole.create!(user: user2, role: role)
    end

    it 'has access to users' do
      expect(role.users).to include(user1, user2)
    end
  end
end
