require 'rails_helper'

RSpec.describe Student::AppointmentPolicy, type: :policy do
  subject { described_class }

  describe '#index?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_appointment).index?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access (for preview)' do
        expect(subject.new(user, :student_appointment).index?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'allows access (for preview)' do
        expect(subject.new(user, :student_appointment).index?).to be true
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).index?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_appointment).create?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).create?).to be false
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).create?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).create?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'allows access' do
        expect(subject.new(user, :student_appointment).destroy?).to be true
      end
    end

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).destroy?).to be false
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).destroy?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_appointment).destroy?).to be false
      end
    end
  end
end
