require 'rails_helper'

RSpec.describe CalendarEventFaculty, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:event) do
    CalendarEvent.create!(
      title: "Test Event",
      start_time: Time.current,
      end_time: 1.hour.from_now,
      program: program
    )
  end
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }

  describe 'associations' do
    subject { CalendarEventFaculty.new(calendar_event: event, vip: vip) }
    it { should belong_to(:calendar_event) }
    it { should belong_to(:vip) }
  end

  describe 'validations' do
    it 'validates uniqueness of calendar_event_id scoped to vip_id' do
      CalendarEventFaculty.create!(calendar_event: event, vip: vip)
      duplicate = CalendarEventFaculty.new(calendar_event: event, vip: vip)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:calendar_event_id]).to be_present
    end

    it 'allows same event with different vips' do
      CalendarEventFaculty.create!(calendar_event: event, vip: vip)
      other_vip = Vip.create!(name: "Dr. Jones", program: program)
      other_association = CalendarEventFaculty.new(calendar_event: event, vip: other_vip)
      expect(other_association).to be_valid
    end

    it 'allows same vip with different events' do
      CalendarEventFaculty.create!(calendar_event: event, vip: vip)
      other_event = CalendarEvent.create!(
        title: "Other Event",
        start_time: 2.hours.from_now,
        end_time: 3.hours.from_now,
        program: program
      )
      other_association = CalendarEventFaculty.new(calendar_event: other_event, vip: vip)
      expect(other_association).to be_valid
    end
  end
end
