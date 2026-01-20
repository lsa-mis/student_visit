require 'rails_helper'

RSpec.describe Student::DashboardPolicy, type: :policy do
  subject { described_class }

  describe '#show?' do
    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'allows access' do
        expect(subject.new(user, :student_dashboard).show?).to be true
      end
    end

    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'denies access' do
        expect(subject.new(user, :student_dashboard).show?).to be false
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        user
      end

      it 'denies access' do
        expect(subject.new(user, :student_dashboard).show?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_dashboard).show?).to be false
      end
    end
  end

  describe '#preview?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, :student_dashboard).preview?).to be true
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, :student_dashboard).preview?).to be true
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'denies access' do
        expect(subject.new(user, :student_dashboard).preview?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, :student_dashboard).preview?).to be false
      end
    end
  end
end
