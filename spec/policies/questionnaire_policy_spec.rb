require 'rails_helper'

RSpec.describe QuestionnairePolicy, type: :policy do
  let(:department) { create(:department) }
  let(:other_department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:other_program) { create(:program, department: other_department) }
  let(:questionnaire) { create(:questionnaire, program: program) }
  let(:other_questionnaire) { create(:questionnaire, program: other_program) }
  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, Questionnaire).index?).to be true
      end
    end

    context 'as department admin' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, Questionnaire).index?).to be true
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, Questionnaire).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, questionnaire).show?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, questionnaire).show?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, questionnaire).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, Questionnaire.new(program: program)).create?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, Questionnaire.new(program: program)).create?).to be true
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, questionnaire).update?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, questionnaire).update?).to be true
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, questionnaire).destroy?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, questionnaire).destroy?).to be true
      end
    end
  end

  describe 'Scope' do
    let!(:questionnaire1) { questionnaire }
    let!(:questionnaire2) { other_questionnaire }

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'returns all questionnaires' do
        resolved = QuestionnairePolicy::Scope.new(user, Questionnaire).resolve
        expect(resolved).to include(questionnaire1, questionnaire2)
      end
    end

    context 'as department admin' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'returns only questionnaires from their departments' do
        resolved = QuestionnairePolicy::Scope.new(user, Questionnaire).resolve
        expect(resolved).to include(questionnaire1)
        expect(resolved).not_to include(questionnaire2)
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'returns no questionnaires' do
        resolved = QuestionnairePolicy::Scope.new(user, Questionnaire).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
