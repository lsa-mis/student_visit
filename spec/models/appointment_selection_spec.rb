require 'rails_helper'

RSpec.describe AppointmentSelection, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }
  let(:vip) { Vip.create!(name: "Dr. Smith", department: department) }
  let(:appointment) do
    Appointment.create!(
      start_time: 1.hour.from_now,
      end_time: 2.hours.from_now,
      program: program,
      vip: vip
    )
  end
  let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }

  describe 'associations' do
    subject { AppointmentSelection.new(appointment: appointment, user: user, action: "selected") }
    it { should belong_to(:appointment) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'requires action' do
      selection = AppointmentSelection.new(appointment: appointment, user: user)
      expect(selection).not_to be_valid
      expect(selection.errors[:action]).to be_present
    end

    it 'validates action inclusion' do
      selection = AppointmentSelection.new(appointment: appointment, user: user, action: "invalid")
      expect(selection).not_to be_valid
      expect(selection.errors[:action]).to be_present
    end

    it 'allows action "selected"' do
      selection = AppointmentSelection.new(appointment: appointment, user: user, action: "selected")
      expect(selection).to be_valid
    end

    it 'allows action "deleted"' do
      selection = AppointmentSelection.new(appointment: appointment, user: user, action: "deleted")
      expect(selection).to be_valid
    end
  end
end
