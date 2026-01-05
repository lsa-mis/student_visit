require 'rails_helper'

RSpec.describe AppointmentPolicy, type: :policy do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
  let(:appointment) { Appointment.create!(start_time: 1.hour.from_now, end_time: 2.hours.from_now, program: program, vip: vip) }
  let(:other_department) { Department.create!(name: "Other Department") }
  let(:other_program) { Program.create!(name: "Other Program", department: other_department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:other_appointment) { Appointment.create!(start_time: 1.hour.from_now, end_time: 2.hours.from_now, program: other_program, vip: Vip.create!(name: "Dr. Jones", program: other_program)) }

  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'allows access' do
        expect(subject.new(user, Appointment.new(program: program)).index?).to be true
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
        expect(subject.new(user, Appointment.new(program: program)).index?).to be true
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'denies access' do
        expect(subject.new(user, Appointment.new(program: program)).index?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        # When user is nil, Current.user should be used, but it will be nil too
        policy = AppointmentPolicy.new(nil, Appointment.new(program: program))
        expect(policy.index?).to be false
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

      it 'allows access to any appointment' do
        expect(subject.new(user, appointment).show?).to be true
        expect(subject.new(user, other_appointment).show?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access to appointments in their department' do
        expect(subject.new(user, appointment).show?).to be true
      end

      it 'denies access to appointments in other departments' do
        expect(subject.new(user, other_appointment).show?).to be false
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'denies access' do
        expect(subject.new(user, appointment).show?).to be false
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
        expect(subject.new(user, Appointment.new(program: program)).create?).to be true
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
        expect(subject.new(user, Appointment.new(program: program)).create?).to be true
      end

      it 'denies access for other departments' do
        expect(subject.new(user, Appointment.new(program: other_program)).create?).to be false
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'denies access' do
        expect(subject.new(user, Appointment.new(program: program)).create?).to be false
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
        expect(subject.new(user, appointment).update?).to be true
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
        expect(subject.new(user, appointment).update?).to be true
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
        expect(subject.new(user, appointment).destroy?).to be true
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
        expect(subject.new(user, appointment).destroy?).to be true
      end
    end
  end

  describe 'Scope' do
    let!(:appointment1) { appointment }
    let!(:appointment2) { other_appointment }

    context 'as super admin' do
      let(:user) do
        user = User.create!(email_address: 'super@example.com', password: 'password123')
        user.add_role('super_admin')
        user
      end

      it 'returns all appointments' do
        resolved = AppointmentPolicy::Scope.new(user, Appointment).resolve
        expect(resolved).to include(appointment1, appointment2)
      end
    end

    context 'as department admin' do
      let(:user) do
        user = User.create!(email_address: 'admin@example.com', password: 'password123')
        user.add_role('department_admin')
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'returns only appointments from their departments' do
        resolved = AppointmentPolicy::Scope.new(user, Appointment).resolve
        expect(resolved).to include(appointment1)
        expect(resolved).not_to include(appointment2)
      end
    end

    context 'as student' do
      let(:user) do
        user = User.create!(email_address: 'student@example.com', password: 'password123')
        user.add_role('student')
        user
      end

      it 'returns no appointments' do
        resolved = AppointmentPolicy::Scope.new(user, Appointment).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
