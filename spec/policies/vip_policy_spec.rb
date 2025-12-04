require 'rails_helper'

RSpec.describe VipPolicy, type: :policy do
  let(:department) { create(:department) }
  let(:other_department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:other_program) { create(:program, department: other_department) }
  let(:vip) { create(:vip, program: program) }
  let(:other_vip) { create(:vip, program: other_program) }
  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, vip).index?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, vip).index?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, vip).index?).to be false
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, vip).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, vip).show?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, vip).show?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, vip).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, Vip.new(program: program)).create?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, Vip.new(program: program)).create?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, Vip.new(program: program)).create?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, vip).update?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, vip).update?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, vip).update?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, vip).destroy?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, vip).destroy?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, vip).destroy?).to be false
      end
    end
  end

  describe 'Scope' do
    let!(:vip1) { vip }
    let!(:vip2) { other_vip }

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'returns all vips' do
        resolved = VipPolicy::Scope.new(user, Vip).resolve
        expect(resolved).to include(vip1, vip2)
      end
    end

    context 'as department admin' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'returns only vips from their departments' do
        resolved = VipPolicy::Scope.new(user, Vip).resolve
        expect(resolved).to include(vip1)
        expect(resolved).not_to include(vip2)
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'returns no vips' do
        resolved = VipPolicy::Scope.new(user, Vip).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
