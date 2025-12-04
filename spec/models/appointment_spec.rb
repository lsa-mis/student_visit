require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
  let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }

  describe 'associations' do
    subject { Appointment.new(program: program, vip: vip, start_time: Time.current, end_time: 1.hour.from_now) }
    it { should belong_to(:program) }
    it { should belong_to(:vip) }
    it { should belong_to(:student).class_name("User").optional }
    it { should have_many(:appointment_selections).dependent(:destroy) }
  end

  describe 'validations' do
    it 'requires start_time' do
      appointment = Appointment.new(end_time: 1.hour.from_now, program: program, vip: vip)
      expect(appointment).not_to be_valid
      expect(appointment.errors[:start_time]).to be_present
    end

    it 'requires end_time' do
      # Create appointment without program to test end_time requirement
      # (The before_validation callback only sets end_time if program is present)
      appointment = Appointment.new(start_time: Time.current, program: nil, vip: vip)
      expect(appointment).not_to be_valid
      expect(appointment.errors[:end_time]).to be_present
    end

    it 'validates end_time is after start_time' do
      appointment = Appointment.new(
        start_time: 1.hour.from_now,
        end_time: Time.current,
        program: program,
        vip: vip
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:end_time]).to include("must be after start time")
    end

    it 'validates end_time is not equal to start_time' do
      time = Time.current
      appointment = Appointment.new(
        start_time: time,
        end_time: time,
        program: program,
        vip: vip
      )
      expect(appointment).not_to be_valid
      expect(appointment.errors[:end_time]).to include("must be after start time")
    end

    it 'is valid with proper times' do
      appointment = Appointment.new(
        start_time: Time.current,
        end_time: 1.hour.from_now,
        program: program,
        vip: vip
      )
      expect(appointment).to be_valid
    end
  end

  describe 'scopes' do
    let!(:available_appointment) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip
      )
    end
    let!(:booked_appointment) do
      Appointment.create!(
        start_time: 3.hours.from_now,
        end_time: 4.hours.from_now,
        program: program,
        vip: vip,
        student: student
      )
    end

    describe '.available' do
      it 'returns appointments without a student' do
        expect(Appointment.available).to include(available_appointment)
        expect(Appointment.available).not_to include(booked_appointment)
      end
    end

    describe '.booked' do
      it 'returns appointments with a student' do
        expect(Appointment.booked).to include(booked_appointment)
        expect(Appointment.booked).not_to include(available_appointment)
      end
    end

    describe '.for_vip' do
      let(:other_vip) { Vip.create!(name: "Dr. Jones", program: program) }
      let!(:other_appointment) do
        Appointment.create!(
          start_time: 5.hours.from_now,
          end_time: 6.hours.from_now,
          program: program,
          vip: other_vip
        )
      end

      it 'returns appointments for the specified VIP' do
        expect(Appointment.for_vip(vip)).to include(available_appointment, booked_appointment)
        expect(Appointment.for_vip(vip)).not_to include(other_appointment)
      end
    end

    describe '.for_student' do
      let(:other_student) { User.create!(email_address: 'other@example.com', password: 'password123') }
      let!(:other_booked) do
        Appointment.create!(
          start_time: 7.hours.from_now,
          end_time: 8.hours.from_now,
          program: program,
          vip: vip,
          student: other_student
        )
      end

      it 'returns appointments for the specified student' do
        expect(Appointment.for_student(student)).to include(booked_appointment)
        expect(Appointment.for_student(student)).not_to include(available_appointment, other_booked)
      end
    end

    describe '.upcoming' do
      let!(:past_appointment) do
        Appointment.create!(
          start_time: 1.hour.ago,
          end_time: 30.minutes.ago,
          program: program,
          vip: vip
        )
      end

      it 'returns appointments with start_time in the future' do
        upcoming = Appointment.upcoming
        expect(upcoming).to include(available_appointment, booked_appointment)
        expect(upcoming).not_to include(past_appointment)
      end

      it 'orders by start_time ascending' do
        upcoming = Appointment.upcoming.to_a
        expect(upcoming.first.start_time).to be < upcoming.last.start_time
      end
    end

    describe '.past' do
      let!(:past_appointment) do
        Appointment.create!(
          start_time: 2.hours.ago,
          end_time: 1.hour.ago,
          program: program,
          vip: vip
        )
      end

      it 'returns appointments with start_time in the past' do
        past = Appointment.past
        expect(past).to include(past_appointment)
        expect(past).not_to include(available_appointment, booked_appointment)
      end

      it 'orders by start_time descending' do
        past_appointment2 = Appointment.create!(
          start_time: 3.hours.ago,
          end_time: 2.5.hours.ago,
          program: program,
          vip: vip
        )
        past = Appointment.past.to_a
        expect(past.first.start_time).to be > past.last.start_time
      end
    end
  end

  describe '#available?' do
    it 'returns true when student_id is nil' do
      appointment = Appointment.new(student_id: nil)
      expect(appointment.available?).to be true
    end

    it 'returns false when student_id is present' do
      appointment = Appointment.new(student_id: student.id)
      expect(appointment.available?).to be false
    end
  end

  describe '#booked?' do
    it 'returns true when student_id is present' do
      appointment = Appointment.new(student_id: student.id)
      expect(appointment.booked?).to be true
    end

    it 'returns false when student_id is nil' do
      appointment = Appointment.new(student_id: nil)
      expect(appointment.booked?).to be false
    end
  end

  describe '#select_by!' do
    let(:appointment) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip
      )
    end

    context 'when appointment is available' do
      it 'assigns the student to the appointment' do
        expect {
          appointment.select_by!(student)
        }.to change { appointment.reload.student_id }.from(nil).to(student.id)
      end

      it 'creates an appointment_selection record' do
        expect {
          appointment.select_by!(student)
        }.to change { AppointmentSelection.count }.by(1)
      end

      it 'creates appointment_selection with action "selected"' do
        appointment.select_by!(student)
        selection = AppointmentSelection.last
        expect(selection.action).to eq('selected')
        expect(selection.user).to eq(student)
        expect(selection.appointment).to eq(appointment)
      end

      it 'returns true' do
        expect(appointment.select_by!(student)).to be true
      end

      it 'wraps in a transaction' do
        # Test that if update fails, selection is not created
        allow(appointment).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(appointment))
        expect {
          begin
            appointment.select_by!(student)
          rescue ActiveRecord::RecordInvalid
            # Expected
          end
        }.not_to change { AppointmentSelection.count }
      end
    end

    context 'when appointment is already booked' do
      before do
        appointment.update!(student: student)
      end

      it 'does not change the student' do
        original_student = appointment.student
        appointment.select_by!(User.create!(email_address: 'other@example.com', password: 'password123'))
        expect(appointment.reload.student).to eq(original_student)
      end

      it 'does not create an appointment_selection' do
        expect {
          appointment.select_by!(User.create!(email_address: 'other@example.com', password: 'password123'))
        }.not_to change { AppointmentSelection.count }
      end

      it 'returns false' do
        expect(appointment.select_by!(User.create!(email_address: 'other@example.com', password: 'password123'))).to be false
      end
    end
  end

  describe '#release!' do
    let(:appointment) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip,
        student: student
      )
    end

    context 'when appointment is booked' do
      it 'removes the student from the appointment' do
        expect {
          appointment.release!
        }.to change { appointment.reload.student_id }.from(student.id).to(nil)
      end

      it 'creates an appointment_selection record with action "deleted"' do
        expect {
          appointment.release!
        }.to change { AppointmentSelection.count }.by(1)

        selection = AppointmentSelection.last
        expect(selection.action).to eq('deleted')
        expect(selection.user).to eq(student)
        expect(selection.appointment).to eq(appointment)
      end

      it 'returns true' do
        expect(appointment.release!).to be true
      end

      it 'wraps in a transaction' do
        # Test that if update fails, selection is not created
        allow(appointment).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(appointment))
        expect {
          begin
            appointment.release!
          rescue ActiveRecord::RecordInvalid
            # Expected
          end
        }.not_to change { AppointmentSelection.count }
      end
    end

    context 'when appointment is already available' do
      before do
        appointment.update!(student: nil)
      end

      it 'does not change the appointment' do
        expect {
          appointment.release!
        }.not_to change { appointment.reload.student_id }
      end

      it 'does not create an appointment_selection' do
        expect {
          appointment.release!
        }.not_to change { AppointmentSelection.count }
      end

      it 'returns false' do
        expect(appointment.release!).to be false
      end
    end
  end
end
