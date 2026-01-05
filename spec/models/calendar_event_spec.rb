require 'rails_helper'

RSpec.describe CalendarEvent, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe 'associations' do
    subject { CalendarEvent.new(program: program, title: "Test", start_time: Time.current, end_time: 1.hour.from_now) }
    it { should belong_to(:program) }
    it { should have_many(:calendar_event_faculties).dependent(:destroy) }
    it { should have_many(:participating_faculty).through(:calendar_event_faculties).source(:vip) }
  end

  describe 'validations' do
    it 'requires title' do
      event = CalendarEvent.new(start_time: Time.current, end_time: 1.hour.from_now, program: program)
      expect(event).not_to be_valid
      expect(event.errors[:title]).to be_present
    end

    it 'requires start_time' do
      event = CalendarEvent.new(title: "Test Event", end_time: 1.hour.from_now, program: program)
      expect(event).not_to be_valid
      expect(event.errors[:start_time]).to be_present
    end

    it 'requires end_time' do
      event = CalendarEvent.new(title: "Test Event", start_time: Time.current, program: program)
      expect(event).not_to be_valid
      expect(event.errors[:end_time]).to be_present
    end

    it 'validates end_time is after start_time' do
      event = CalendarEvent.new(
        title: "Test Event",
        start_time: 1.hour.from_now,
        end_time: Time.current,
        program: program
      )
      expect(event).not_to be_valid
      expect(event.errors[:end_time]).to include("must be after start time")
    end

    it 'validates start_time is on a held_on_date when program has held_on_dates' do
      program.update!(held_on_dates: [ Date.tomorrow.to_s ])
      event = CalendarEvent.new(
        title: "Test Event",
        start_time: Date.today.beginning_of_day,
        end_time: Date.today.beginning_of_day + 1.hour,
        program: program
      )
      expect(event).not_to be_valid
      expect(event.errors[:start_time]).to be_present
    end

    it 'allows start_time on any date when program has no held_on_dates' do
      program.update!(held_on_dates: nil)
      event = CalendarEvent.new(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
      expect(event).to be_valid
    end

    it 'allows start_time on any date when program has empty held_on_dates' do
      program.update!(held_on_dates: [])
      event = CalendarEvent.new(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
      expect(event).to be_valid
    end

    it 'is valid with proper attributes' do
      event = CalendarEvent.new(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
      expect(event).to be_valid
    end
  end

  describe 'scopes' do
    let!(:upcoming_event) do
      CalendarEvent.create!(
        title: "Upcoming Event",
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program
      )
    end
    let!(:past_event) do
      CalendarEvent.create!(
        title: "Past Event",
        start_time: 2.hours.ago,
        end_time: 1.hour.ago,
        program: program
      )
    end

    describe '.upcoming' do
      it 'returns events with start_time in the future' do
        expect(CalendarEvent.upcoming).to include(upcoming_event)
        expect(CalendarEvent.upcoming).not_to include(past_event)
      end

      it 'orders by start_time ascending' do
        upcoming_event2 = CalendarEvent.create!(
          title: "Later Event",
          start_time: 3.hours.from_now,
          end_time: 4.hours.from_now,
          program: program
        )
        upcoming = CalendarEvent.upcoming.to_a
        expect(upcoming.first.start_time).to be < upcoming.last.start_time
      end
    end

    describe '.past' do
      it 'returns events with start_time in the past' do
        expect(CalendarEvent.past).to include(past_event)
        expect(CalendarEvent.past).not_to include(upcoming_event)
      end

      it 'orders by start_time descending' do
        past_event2 = CalendarEvent.create!(
          title: "Earlier Event",
          start_time: 3.hours.ago,
          end_time: 2.5.hours.ago,
          program: program
        )
        past = CalendarEvent.past.to_a
        expect(past.first.start_time).to be > past.last.start_time
      end
    end
  end

  describe 'rich text fields' do
    it 'has description field' do
      event = CalendarEvent.create!(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
      event.description = "Test description"
      expect(event.description).to be_present
    end

    it 'has location field' do
      event = CalendarEvent.create!(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
      event.location = "Test location"
      expect(event.location).to be_present
    end

    it 'has notes field' do
      event = CalendarEvent.create!(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
      event.notes = "Test notes"
      expect(event.notes).to be_present
    end
  end

  describe 'participating_faculty association' do
    let(:vip1) { Vip.create!(name: "Dr. Smith", program: program) }
    let(:vip2) { Vip.create!(name: "Dr. Jones", program: program) }
    let(:event) do
      CalendarEvent.create!(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
    end

    it 'can have multiple participating faculty' do
      event.participating_faculty << vip1
      event.participating_faculty << vip2
      expect(event.participating_faculty).to include(vip1, vip2)
    end

    it 'destroys calendar_event_faculties when event is destroyed' do
      event.participating_faculty << vip1
      event_id = event.id
      event.destroy
      expect(CalendarEventFaculty.where(calendar_event_id: event_id)).to be_empty
    end
  end
end
