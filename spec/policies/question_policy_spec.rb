require 'rails_helper'

RSpec.describe QuestionPolicy, type: :policy do
  let(:department) { create(:department) }
  let(:other_department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:other_program) { create(:program, department: other_department) }
  let(:questionnaire) { create(:questionnaire, program: program) }
  let(:other_questionnaire) { create(:questionnaire, program: other_program) }
  let(:question) { create(:question, questionnaire: questionnaire) }
  let(:other_question) { create(:question, questionnaire: other_questionnaire) }
  subject { described_class }

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, Question.new(questionnaire: questionnaire)).create?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, Question.new(questionnaire: questionnaire)).create?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, Question.new(questionnaire: questionnaire)).create?).to be false
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, Question.new(questionnaire: questionnaire)).create?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, question).update?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, question).update?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, question).update?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, question).destroy?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, question).destroy?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, question).destroy?).to be false
      end
    end
  end
end
