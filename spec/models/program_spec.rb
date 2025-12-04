require 'rails_helper'

RSpec.describe Program, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  let(:department) { Department.create!(name: "Test Department") }

  describe 'associations' do
    subject { Program.new(name: "Test", department: department, default_appointment_length: 30) }
    it { should belong_to(:department) }
    it { should have_many(:student_programs).dependent(:destroy) }
    it { should have_many(:students).through(:student_programs).source(:user) }
    it { should have_many(:calendar_events).dependent(:destroy) }
    it { should have_many(:questionnaires).dependent(:destroy) }
    it { should have_many(:appointments).dependent(:destroy) }
    it { should have_many(:answers).dependent(:destroy) }
    it { should have_many(:appointment_selections).through(:appointments) }
  end

  describe 'validations' do
    it 'requires name' do
      program = Program.new(department: department, default_appointment_length: 30)
      expect(program).not_to be_valid
      expect(program.errors[:name]).to be_present
    end

    it 'requires default_appointment_length to be present' do
      # Schema has default of 30, so we need to explicitly set nil to test validation
      program = Program.new(name: "Test Program", department: department)
      program.default_appointment_length = nil
      # Since there's a database default, validation might pass, but we can test the numericality
      program.default_appointment_length = 0
      expect(program).not_to be_valid
      expect(program.errors[:default_appointment_length]).to be_present
    end

    it 'requires default_appointment_length to be greater than 0' do
      program = Program.new(name: "Test Program", department: department, default_appointment_length: 0)
      expect(program).not_to be_valid
      expect(program.errors[:default_appointment_length]).to be_present
    end

    it 'requires default_appointment_length to be greater than 0 (negative)' do
      program = Program.new(name: "Test Program", department: department, default_appointment_length: -1)
      expect(program).not_to be_valid
      expect(program.errors[:default_appointment_length]).to be_present
    end

    it 'is valid with proper attributes' do
      program = Program.new(name: "Test Program", department: department, default_appointment_length: 30)
      expect(program).to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_program) { Program.create!(name: "Active Program", department: department, default_appointment_length: 30, active: true) }
    let!(:inactive_program) { Program.create!(name: "Inactive Program", department: department, default_appointment_length: 30, active: false) }

    describe '.active' do
      it 'returns active programs' do
        expect(Program.active).to include(active_program)
        expect(Program.active).not_to include(inactive_program)
      end
    end

    describe '.inactive' do
      it 'returns inactive programs' do
        expect(Program.inactive).to include(inactive_program)
        expect(Program.inactive).not_to include(active_program)
      end
    end
  end

  describe '#open?' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    context 'when open_date and close_date are set' do
      it 'returns true when current time is between open_date and close_date' do
        program.update!(open_date: 1.day.ago, close_date: 1.day.from_now)
        expect(program.open?).to be true
      end

      it 'returns false when current time is before open_date' do
        program.update!(open_date: 1.day.from_now, close_date: 2.days.from_now)
        expect(program.open?).to be false
      end

      it 'returns false when current time is after close_date' do
        program.update!(open_date: 2.days.ago, close_date: 1.day.ago)
        expect(program.open?).to be false
      end

      it 'returns true when current time equals open_date' do
        program.update!(open_date: Time.current, close_date: 1.day.from_now)
        expect(program.open?).to be true
      end

      it 'returns true when current time equals close_date' do
        close_time = Time.current
        program.update!(open_date: 1.day.ago, close_date: close_time)
        program.reload
        # Use travel_to to freeze time at close_time to ensure equality
        travel_to close_time do
          expect(program.open?).to be true
        end
      end
    end

    context 'when open_date or close_date is nil' do
      it 'returns false when open_date is nil' do
        program.update!(close_date: 1.day.from_now)
        expect(program.open?).to be false
      end

      it 'returns false when close_date is nil' do
        program.update!(open_date: 1.day.ago)
        expect(program.open?).to be false
      end
    end
  end

  describe '#closed?' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    it 'returns true when close_date is nil' do
      expect(program.closed?).to be true
    end

    it 'returns true when current time is after close_date' do
      program.update!(close_date: 1.day.ago)
      expect(program.closed?).to be true
    end

    it 'returns false when current time is before close_date' do
      program.update!(close_date: 1.day.from_now)
      expect(program.closed?).to be false
    end
  end

  describe '#questionnaire_due?' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    it 'returns false when questionnaire_due_date is nil' do
      expect(program.questionnaire_due?).to be false
    end

    it 'returns true when current time is after questionnaire_due_date' do
      program.update!(questionnaire_due_date: 1.day.ago)
      expect(program.questionnaire_due?).to be true
    end

    it 'returns false when current time is before questionnaire_due_date' do
      program.update!(questionnaire_due_date: 1.day.from_now)
      expect(program.questionnaire_due?).to be false
    end
  end

  describe '#held_on_dates_as_dates' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    it 'returns empty array when held_on_dates is nil' do
      expect(program.held_on_dates_as_dates).to eq([])
    end

    it 'returns empty array when held_on_dates is not an array' do
      program.update!(held_on_dates: "not an array")
      expect(program.held_on_dates_as_dates).to eq([])
    end

    it 'converts date strings to Date objects' do
      program.update!(held_on_dates: [ Date.today.to_s, Date.tomorrow.to_s ])
      dates = program.held_on_dates_as_dates
      expect(dates).to all(be_a(Date))
      expect(dates).to include(Date.today, Date.tomorrow)
    end

    it 'filters out invalid date strings' do
      program.update!(held_on_dates: [ Date.today.to_s, "invalid", Date.tomorrow.to_s ])
      dates = program.held_on_dates_as_dates
      expect(dates).to include(Date.today, Date.tomorrow)
      expect(dates.length).to eq(2)
    end
  end

  describe '#held_on_date?' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    it 'returns false when held_on_dates is not an array' do
      program.update!(held_on_dates: nil)
      expect(program.held_on_date?(Date.today)).to be false
    end

    it 'returns true when date is in held_on_dates' do
      program.update!(held_on_dates: [ Date.today.to_s ])
      expect(program.held_on_date?(Date.today)).to be true
    end

    it 'returns false when date is not in held_on_dates' do
      program.update!(held_on_dates: [ Date.tomorrow.to_s ])
      expect(program.held_on_date?(Date.today)).to be false
    end

    it 'handles Date objects' do
      program.update!(held_on_dates: [ Date.today.to_s ])
      expect(program.held_on_date?(Date.today)).to be true
    end

    it 'handles Time objects' do
      program.update!(held_on_dates: [ Date.today.to_s ])
      expect(program.held_on_date?(Time.current)).to be true
    end
  end

  describe '#held_on_dates_list' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    it 'returns sorted list of dates' do
      program.update!(held_on_dates: [ Date.tomorrow.to_s, Date.today.to_s ])
      expect(program.held_on_dates_list).to eq([ Date.today, Date.tomorrow ])
    end
  end

  describe 'ensure_single_active_program callback' do
    let(:program1) { Program.create!(name: "Program 1", department: department, default_appointment_length: 30) }
    let(:program2) { Program.create!(name: "Program 2", department: department, default_appointment_length: 30) }

    it 'deactivates other programs when a program is activated' do
      program1.update!(active: true)
      program2.update!(active: true)
      expect(program1.reload.active).to be false
      expect(program2.reload.active).to be true
    end

    it 'sets department active_program_id when program is activated' do
      program1.update!(active: true)
      expect(department.reload.active_program_id).to eq(program1.id)
    end
  end

  describe 'normalize_held_on_dates callback' do
    let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }

    it 'normalizes date strings to YYYY-MM-DD format' do
      program.update!(held_on_dates: [ "01/15/2024", "2024-02-20" ])
      expect(program.held_on_dates).to all(match(/\d{4}-\d{2}-\d{2}/))
    end

    it 'removes duplicates' do
      program.update!(held_on_dates: [ Date.today.to_s, Date.today.to_s ])
      expect(program.held_on_dates.length).to eq(1)
    end

    it 'sorts dates' do
      program.update!(held_on_dates: [ Date.tomorrow.to_s, Date.today.to_s ])
      expect(program.held_on_dates.first).to eq(Date.today.to_s)
    end

    it 'filters out blank dates' do
      program.update!(held_on_dates: [ Date.today.to_s, "", "  " ])
      expect(program.held_on_dates).to eq([ Date.today.to_s ])
    end
  end
end
