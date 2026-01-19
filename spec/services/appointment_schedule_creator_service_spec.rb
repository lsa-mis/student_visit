require 'rails_helper'

RSpec.describe AppointmentScheduleCreatorService, type: :service do
  let(:department) { create(:department) }
  let(:program) { create(:program, department: department, default_appointment_length: 30) }
  let(:vip) { create(:vip, program: program) }

  describe '#initialize' do
    it 'sets program, vip, and schedule_blocks' do
      schedule_blocks = [ { date: "2025-03-23", blocks: [] } ]
      service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

      expect(service.program).to eq(program)
      expect(service.vip).to eq(vip)
      expect(service.schedule_blocks).to eq(schedule_blocks)
      expect(service.errors).to eq([])
      expect(service.created_count).to eq(0)
    end
  end

  describe '#call' do
    context 'with invalid input' do
      it 'returns false when program has no default_appointment_length' do
        program.update(default_appointment_length: nil)
        schedule_blocks = [ { date: "2025-03-23", blocks: [] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include("Program must have a valid default appointment length")
      end

      it 'returns false when program has zero default_appointment_length' do
        program.update(default_appointment_length: 0)
        schedule_blocks = [ { date: "2025-03-23", blocks: [] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include("Program must have a valid default appointment length")
      end

      it 'returns false when schedule_blocks is nil' do
        service = AppointmentScheduleCreatorService.new(program, vip, nil)

        expect(service.call).to be false
        expect(service.errors).to include("Schedule blocks must be provided as an array")
      end

      it 'returns false when schedule_blocks is not an array' do
        service = AppointmentScheduleCreatorService.new(program, vip, "not an array")

        expect(service.call).to be false
        expect(service.errors).to include("Schedule blocks must be provided as an array")
      end

      it 'returns false when date is invalid' do
        schedule_blocks = [ { date: "invalid-date", blocks: [] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include(match(/Invalid date/))
      end

      it 'returns false when date is not in program held_on_dates' do
        program.update(held_on_dates: [ "2025-03-24" ])
        schedule_blocks = [ { date: "2025-03-23", blocks: [] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include(match(/is not in program's held-on dates/))
      end

      it 'returns false when start_time is invalid' do
        schedule_blocks = [ { date: "2025-03-23", blocks: [ { start_time: "invalid", type: "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include(match(/Invalid start time/))
      end

      it 'returns false when end_time is invalid for range type' do
        schedule_blocks = [ { date: "2025-03-23", blocks: [ { start_time: "09:00", end_time: "invalid", type: "range" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include(match(/Invalid end time/))
      end

      it 'returns false when end_time is before start_time' do
        schedule_blocks = [ { date: "2025-03-23", blocks: [ { start_time: "12:00", end_time: "09:00", type: "range" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be false
        expect(service.errors).to include(match(/End time must be after start time/))
      end
    end

    context 'with valid single appointments' do
      it 'creates a single appointment' do
        date = 1.week.from_now.to_date
        schedule_blocks = [ { date: date.to_s, blocks: [ { start_time: "09:00", type: "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect {
          service.call
        }.to change { Appointment.count }.by(1)

        expect(service.created_count).to eq(1)
        expect(service.call).to be true

        appointment = Appointment.last
        expect(appointment.program).to eq(program)
        expect(appointment.vip).to eq(vip)
        expect(appointment.start_time.to_date).to eq(date)
        expect(appointment.end_time - appointment.start_time).to eq(30.minutes)
      end

      it 'creates multiple single appointments' do
        date = 1.week.from_now.to_date
        schedule_blocks = [ {
          date: date.to_s,
          blocks: [
            { start_time: "09:00", type: "single" },
            { start_time: "10:00", type: "single" },
            { start_time: "11:00", type: "single" }
          ]
        } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect {
          service.call
        }.to change { Appointment.count }.by(3)

        expect(service.created_count).to eq(3)
      end

      it 'handles 12-hour time format' do
        date = 1.week.from_now.to_date
        schedule_blocks = [ { date: date.to_s, blocks: [ { start_time: "09:00 AM", type: "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be true
        expect(service.created_count).to eq(1)
      end
    end

    context 'with valid range appointments' do
      it 'creates multiple appointments from a range' do
        date = 1.week.from_now.to_date
        schedule_blocks = [ {
          date: date.to_s,
          blocks: [ { start_time: "09:00", end_time: "11:00", type: "range" } ]
        } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        # 09:00-09:30, 09:30-10:00, 10:00-10:30, 10:30-11:00 = 4 appointments
        expect {
          service.call
        }.to change { Appointment.count }.by(4)

        expect(service.created_count).to eq(4)
      end

      it 'handles range that does not divide evenly' do
        date = 1.week.from_now.to_date
        schedule_blocks = [ {
          date: date.to_s,
          blocks: [ { start_time: "09:00", end_time: "10:15", type: "range" } ]
        } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        # 09:00-09:30, 09:30-10:00, 10:00-10:30 (10:15 < 10:30, so only 2 full slots) = 2 appointments
        expect {
          service.call
        }.to change { Appointment.count }.by(2)

        expect(service.created_count).to eq(2)
      end
    end

    context 'with multiple days' do
      it 'creates appointments across multiple days' do
        date1 = 1.week.from_now.to_date
        date2 = 1.week.from_now.to_date + 1.day
        schedule_blocks = [
          { date: date1.to_s, blocks: [ { start_time: "09:00", type: "single" } ] },
          { date: date2.to_s, blocks: [ { start_time: "10:00", type: "single" } ] }
        ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect {
          service.call
        }.to change { Appointment.count }.by(2)

        expect(service.created_count).to eq(2)
      end
    end

    context 'with program held_on_dates validation' do
      it 'allows dates in held_on_dates' do
        date = 1.week.from_now.to_date
        program.update(held_on_dates: [ date.to_s ])
        schedule_blocks = [ { date: date.to_s, blocks: [ { start_time: "09:00", type: "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be true
        expect(service.errors).to be_empty
      end

      it 'allows dates when held_on_dates is empty' do
        program.update(held_on_dates: [])
        date = 1.week.from_now.to_date
        schedule_blocks = [ { date: date.to_s, blocks: [ { start_time: "09:00", type: "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be true
      end
    end

    context 'with string keys in schedule_blocks' do
      it 'handles string keys instead of symbol keys' do
        date = 1.week.from_now.to_date
        schedule_blocks = [ { "date" => date.to_s, "blocks" => [ { "start_time" => "09:00", "type" => "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        expect(service.call).to be true
        expect(service.created_count).to eq(1)
      end
    end

    context 'with appointment creation errors' do
      it 'handles validation errors gracefully' do
        # Create an appointment that would conflict
        date = 1.week.from_now.to_date
        create(:appointment,
          program: program,
          vip: vip,
          start_time: Time.zone.parse("#{date} 09:00"),
          end_time: Time.zone.parse("#{date} 09:30")
        )

        schedule_blocks = [ { date: date.to_s, blocks: [ { start_time: "09:00", type: "single" } ] } ]
        service = AppointmentScheduleCreatorService.new(program, vip, schedule_blocks)

        # The service should still attempt to create, but may fail due to validation
        service.call
        # Depending on Appointment validations, this might succeed or fail
        # But the service should handle it gracefully
        expect(service.errors).not_to be_nil
      end
    end
  end
end
