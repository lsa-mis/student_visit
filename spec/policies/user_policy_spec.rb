require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:student_user) { create(:user, :with_student_role) }
  let(:other_student) { create(:user, :with_student_role) }
  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, User).index?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, User).index?).to be false
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, User).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access to any user' do
        expect(subject.new(user, student_user).show?).to be true
      end
    end

    context 'as the user themselves' do
      let(:user) { student_user }

      it 'allows access' do
        expect(subject.new(user, user).show?).to be true
      end
    end

    context 'as department admin viewing student in their program' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        StudentProgram.create!(user: student_user, program: program)
        user
      end

      it 'allows access' do
        expect(subject.new(user, student_user).show?).to be true
      end
    end

    context 'as department admin viewing student not in their program' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, other_student).show?).to be false
      end
    end

    context 'as student viewing another student' do
      let(:user) { student_user }

      it 'denies access' do
        expect(subject.new(user, other_student).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, User).create?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, User).create?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, student_user).update?).to be true
      end
    end

    context 'as the user themselves' do
      let(:user) { student_user }

      it 'allows access' do
        expect(subject.new(user, user).update?).to be true
      end
    end

    context 'as department admin updating student in their program' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        StudentProgram.create!(user: student_user, program: program)
        user
      end

      it 'allows access' do
        expect(subject.new(user, student_user).update?).to be true
      end
    end

    context 'as department admin updating student not in their program' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, other_student).update?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, student_user).destroy?).to be true
      end
    end

    context 'as department admin removing student from their program' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        StudentProgram.create!(user: student_user, program: program)
        user
      end

      it 'allows access' do
        expect(subject.new(user, student_user).destroy?).to be true
      end
    end

    context 'as department admin removing student not in their program' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, other_student).destroy?).to be false
      end
    end

    context 'as the user themselves' do
      let(:user) { student_user }

      it 'denies access' do
        expect(subject.new(user, user).destroy?).to be false
      end
    end
  end

  describe 'Scope' do
    let!(:user1) { create(:user, :with_student_role) }
    let!(:user2) { create(:user, :with_student_role) }

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'returns all users' do
        resolved = UserPolicy::Scope.new(user, User).resolve
        expect(resolved).to include(user1, user2, user)
      end
    end

    context 'as regular user' do
      let(:user) { user1 }

      it 'returns only themselves' do
        resolved = UserPolicy::Scope.new(user, User).resolve
        expect(resolved).to include(user)
        expect(resolved).not_to include(user2)
      end
    end
  end
end
