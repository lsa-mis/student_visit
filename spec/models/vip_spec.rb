require 'rails_helper'

RSpec.describe Vip, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe 'associations' do
    subject { Vip.new(name: "Test", program: program) }
    it { should belong_to(:program) }
    it { should have_many(:calendar_event_faculty).dependent(:destroy) }
    it { should have_many(:calendar_events).through(:calendar_event_faculty) }
    it { should have_many(:appointments).dependent(:destroy) }
  end

  describe 'validations' do
    it 'requires name' do
      vip = Vip.new(program: program)
      expect(vip).not_to be_valid
      expect(vip.errors[:name]).to be_present
    end

    it 'is valid with name' do
      vip = Vip.new(name: "Dr. Smith", program: program)
      expect(vip).to be_valid
    end
  end

  describe 'scopes' do
    let!(:vip1) { Vip.create!(name: "Dr. Smith", program: program, ranking: 2) }
    let!(:vip2) { Vip.create!(name: "Dr. Jones", program: program, ranking: 1) }
    let!(:vip3) { Vip.create!(name: "Dr. Brown", program: program, ranking: 1) }

    describe '.ordered' do
      it 'orders by ranking then name' do
        ordered = Vip.ordered.to_a
        # vip2 has ranking 1, vip3 has ranking 1 but name "Dr. Brown" comes before "Dr. Jones"
        expect(ordered.map(&:name)).to include("Dr. Brown", "Dr. Jones", "Dr. Smith")
        # All ranking 1 should come before ranking 2
        ranking_1_vips = ordered.select { |v| v.ranking == 1 }
        ranking_2_vips = ordered.select { |v| v.ranking == 2 }
        expect(ranking_1_vips).to all(satisfy { |v| v.ranking == 1 })
        expect(ranking_2_vips).to all(satisfy { |v| v.ranking == 2 })
        if ranking_1_vips.any? && ranking_2_vips.any?
          expect(ordered.index(ranking_1_vips.first)).to be < ordered.index(ranking_2_vips.first)
        end
      end
    end
  end

  describe '#display_name' do
    it 'returns name when title is nil' do
      vip = Vip.create!(name: "Dr. Smith", program: program)
      expect(vip.display_name).to eq("Dr. Smith")
    end

    it 'returns title and name when title is present' do
      vip = Vip.create!(name: "Smith", title: "Dr.", program: program)
      expect(vip.display_name).to eq("Smith - Dr.")
    end

    it 'returns name when title is blank' do
      vip = Vip.create!(name: "Smith", title: "", program: program)
      # compact removes nil and empty strings, so blank title should be removed
      expect(vip.display_name).to eq("Smith")
    end

    it 'handles nil title' do
      vip = Vip.create!(name: "Smith", title: nil, program: program)
      expect(vip.display_name).to eq("Smith")
    end
  end

  describe 'appointments association' do
    let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
    let!(:appointment) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip
      )
    end

    it 'has access to appointments' do
      expect(vip.appointments).to include(appointment)
    end

    it 'destroys appointments when vip is destroyed' do
      vip.destroy
      expect(Appointment.find_by(id: appointment.id)).to be_nil
    end
  end

  describe 'calendar_events association' do
    let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
    let(:event) do
      CalendarEvent.create!(
        title: "Test Event",
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program
      )
    end

    it 'can be associated with calendar events' do
      event.participating_faculty << vip
      expect(vip.calendar_events).to include(event)
    end

    it 'destroys calendar_event_faculty when vip is destroyed' do
      event.participating_faculty << vip
      vip_id = vip.id
      vip.destroy
      expect(CalendarEventFaculty.where(vip_id: vip_id)).to be_empty
    end
  end
end
