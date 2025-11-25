require 'rails_helper'

RSpec.describe DepartmentPolicy, type: :policy do
  let(:department) { Department.create!(name: "Test Department") }
  let(:other_department) { Department.create!(name: "Other Department") }

  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, Department).index?).to be true
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, Department).index?).to be true
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'denies access' do
        expect(subject.new(user, Department).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access to any department' do
        expect(subject.new(user, department).show?).to be true
        expect(subject.new(user, other_department).show?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access to their department' do
        expect(subject.new(user, department).show?).to be true
      end

      it 'denies access to other departments' do
        expect(subject.new(user, other_department).show?).to be false
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'denies access' do
        expect(subject.new(user, department).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, Department.new).create?).to be true
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, Department.new).create?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, department).update?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, department).update?).to be true
      end

      it 'denies access to other departments' do
        expect(subject.new(user, other_department).update?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, department).destroy?).to be true
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, department).destroy?).to be false
      end
    end
  end

  describe 'Scope' do
    let!(:department1) { department }
    let!(:department2) { other_department }

    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'returns all departments' do
        resolved = DepartmentPolicy::Scope.new(user, Department).resolve
        expect(resolved).to include(department1, department2)
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'returns only their departments' do
        resolved = DepartmentPolicy::Scope.new(user, Department).resolve
        expect(resolved).to include(department1)
        expect(resolved).not_to include(department2)
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'returns no departments' do
        resolved = DepartmentPolicy::Scope.new(user, Department).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
