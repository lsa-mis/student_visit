require 'rails_helper'

RSpec.describe Student::CalendarPolicy, type: :policy do
  subject { described_class }

  describe '#show?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_calendar).show?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access (admin preview)' do
        expect(subject.new(user, :student_calendar).show?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'allows access (admin preview)' do
        expect(subject.new(user, :student_calendar).show?).to be true
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_calendar).show?).to be false
      end
    end
  end
end
