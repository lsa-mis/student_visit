require 'rails_helper'

RSpec.describe Student::QuestionnairePolicy, type: :policy do
  subject { described_class }

  describe '#index?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_questionnaire).index?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).index?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_questionnaire).show?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).show?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).show?).to be false
      end
    end
  end

  describe '#edit?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_questionnaire).edit?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).edit?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).edit?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_questionnaire).update?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).update?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_questionnaire).update?).to be false
      end
    end
  end
end
