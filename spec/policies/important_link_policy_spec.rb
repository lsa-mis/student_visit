require 'rails_helper'

RSpec.describe ImportantLinkPolicy, type: :policy do
  let(:department) { create(:department) }
  let(:other_department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:other_program) { create(:program, department: other_department) }
  let(:important_link) { create(:important_link, program: program) }
  let(:other_important_link) { create(:important_link, program: other_program) }
  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, important_link).index?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, important_link).index?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, important_link).index?).to be false
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, important_link).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, important_link).show?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, important_link).show?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, important_link).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, ImportantLink.new(program: program)).create?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, ImportantLink.new(program: program)).create?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, ImportantLink.new(program: program)).create?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, important_link).update?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, important_link).update?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, important_link).update?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, important_link).destroy?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, important_link).destroy?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, important_link).destroy?).to be false
      end
    end
  end

  describe 'Scope' do
    let!(:link1) { important_link }
    let!(:link2) { other_important_link }

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'returns all important links' do
        resolved = ImportantLinkPolicy::Scope.new(user, ImportantLink).resolve
        expect(resolved).to include(link1, link2)
      end
    end

    context 'as department admin' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'returns only links from their departments' do
        resolved = ImportantLinkPolicy::Scope.new(user, ImportantLink).resolve
        expect(resolved).to include(link1)
        expect(resolved).not_to include(link2)
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'returns no links' do
        resolved = ImportantLinkPolicy::Scope.new(user, ImportantLink).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
