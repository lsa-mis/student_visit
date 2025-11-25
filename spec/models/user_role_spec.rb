require 'rails_helper'

RSpec.describe UserRole, type: :model do
  let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }
  let(:role) { Role.create!(name: "test_role") }

  describe 'associations' do
    subject { UserRole.new(user: user, role: role) }
    it { should belong_to(:user) }
    it { should belong_to(:role) }
  end

  describe 'validations' do
    it 'validates uniqueness of user_id scoped to role_id' do
      UserRole.create!(user: user, role: role)
      duplicate = UserRole.new(user: user, role: role)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows same user with different roles' do
      UserRole.create!(user: user, role: role)
      other_role = Role.create!(name: "other_role")
      other_user_role = UserRole.new(user: user, role: other_role)
      expect(other_user_role).to be_valid
    end

    it 'allows same role with different users' do
      UserRole.create!(user: user, role: role)
      other_user = User.create!(email_address: 'other@example.com', password: 'password123')
      other_user_role = UserRole.new(user: other_user, role: role)
      expect(other_user_role).to be_valid
    end
  end
end
