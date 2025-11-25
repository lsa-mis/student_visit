require 'rails_helper'

RSpec.describe BulkCalendarEventUploadService, type: :service do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }
  let(:file) { double('file', original_filename: 'events.csv', path: '/tmp/events.csv') }

  describe '#initialize' do
    it 'sets program and file' do
      service = BulkCalendarEventUploadService.new(program, file)
      expect(service.program).to eq(program)
      expect(service.file).to eq(file)
    end

    it 'initializes errors, success_count, and failure_count' do
      service = BulkCalendarEventUploadService.new(program, file)
      expect(service.errors).to eq([])
      expect(service.success_count).to eq(0)
      expect(service.failure_count).to eq(0)
    end
  end

  describe '#call' do
    context 'with invalid file' do
      it 'returns false when file is nil' do
        service = BulkCalendarEventUploadService.new(program, nil)
        expect(service.call).to be false
        expect(service.errors).to include("No file provided")
      end

      it 'returns false when file type is invalid' do
        invalid_file = double('file', original_filename: 'events.txt')
        service = BulkCalendarEventUploadService.new(program, invalid_file)
        expect(service.call).to be false
        expect(service.errors).to include("Invalid file type. Please upload a CSV or Excel file.")
      end
    end

    context 'with valid CSV file' do
      let(:csv_content) do
        "Title,Start Time,End Time,Description,Location,Notes,Mandatory\n" \
        "Event 1,#{(Time.current + 1.hour).strftime('%m/%d/%Y %H:%M')},#{(Time.current + 2.hours).strftime('%m/%d/%Y %H:%M')},Description 1,Location 1,Notes 1,true\n" \
        "Event 2,#{(Time.current + 3.hours).strftime('%m/%d/%Y %H:%M')},#{(Time.current + 4.hours).strftime('%m/%d/%Y %H:%M')},Description 2,Location 2,Notes 2,false\n"
      end
      let(:csv_file) { Tempfile.new(['events', '.csv']) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('events.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'processes valid rows and creates calendar events' do
        service = BulkCalendarEventUploadService.new(program, file)
        expect {
          service.call
        }.to change { CalendarEvent.count }.by(2)
        expect(service.success_count).to eq(2)
        expect(service.failure_count).to eq(0)
      end

      it 'sets event attributes correctly' do
        service = BulkCalendarEventUploadService.new(program, file)
        service.call
        event = CalendarEvent.last
        expect(event.title).to eq("Event 2")
        expect(event.mandatory).to be false
      end

      it 'sets mandatory to true when value is "true"' do
        service = BulkCalendarEventUploadService.new(program, file)
        service.call
        event = CalendarEvent.first
        expect(event.mandatory).to be true
      end

      it 'returns true when at least one event is created' do
        service = BulkCalendarEventUploadService.new(program, file)
        expect(service.call).to be true
      end
    end

    context 'with invalid rows' do
      let(:csv_content) do
        "Title,Start Time,End Time,Description,Location,Notes,Mandatory\n" \
        ",#{(Time.current + 1.hour).strftime('%m/%d/%Y %H:%M')},#{(Time.current + 2.hours).strftime('%m/%d/%Y %H:%M')},Description,Location,Notes,true\n" \
        "Event,invalid,invalid,Description,Location,Notes,true\n"
      end
      let(:csv_file) { Tempfile.new(['events', '.csv']) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('events.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'tracks failures and errors' do
        service = BulkCalendarEventUploadService.new(program, file)
        service.call
        expect(service.failure_count).to be > 0
        expect(service.errors).not_to be_empty
      end

      it 'skips rows with blank title' do
        service = BulkCalendarEventUploadService.new(program, file)
        service.call
        expect(CalendarEvent.where(title: '')).to be_empty
      end
    end

    describe '#parse_boolean' do
      let(:service) { BulkCalendarEventUploadService.new(program, file) }

      it 'parses "true" as true' do
        expect(service.send(:parse_boolean, 'true')).to be true
        expect(service.send(:parse_boolean, 'TRUE')).to be true
        expect(service.send(:parse_boolean, 'True')).to be true
      end

      it 'parses "1" as true' do
        expect(service.send(:parse_boolean, '1')).to be true
      end

      it 'parses "yes" and "y" as true' do
        expect(service.send(:parse_boolean, 'yes')).to be true
        expect(service.send(:parse_boolean, 'y')).to be true
        expect(service.send(:parse_boolean, 'YES')).to be true
      end

      it 'parses blank values as false' do
        expect(service.send(:parse_boolean, '')).to be false
        expect(service.send(:parse_boolean, nil)).to be false
      end

      it 'parses other values as false' do
        expect(service.send(:parse_boolean, 'false')).to be false
        expect(service.send(:parse_boolean, '0')).to be false
        expect(service.send(:parse_boolean, 'no')).to be false
      end
    end
  end
end
