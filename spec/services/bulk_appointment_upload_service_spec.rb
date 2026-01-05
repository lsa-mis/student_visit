require 'rails_helper'

RSpec.describe BulkAppointmentUploadService, type: :service do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
  let(:file) { double('file', original_filename: 'appointments.csv', path: '/tmp/appointments.csv') }

  describe '#initialize' do
    it 'sets program, vip, and file' do
      service = BulkAppointmentUploadService.new(program, vip, file)
      expect(service.program).to eq(program)
      expect(service.vip).to eq(vip)
      expect(service.file).to eq(file)
    end

    it 'initializes errors, success_count, and failure_count' do
      service = BulkAppointmentUploadService.new(program, vip, file)
      expect(service.errors).to eq([])
      expect(service.success_count).to eq(0)
      expect(service.failure_count).to eq(0)
    end
  end

  describe '#call' do
    context 'with invalid file' do
      it 'returns false when file is nil' do
        service = BulkAppointmentUploadService.new(program, vip, nil)
        expect(service.call).to be false
        expect(service.errors).to include("No file provided")
      end

      it 'returns false when file type is invalid' do
        invalid_file = double('file', original_filename: 'appointments.txt')
        service = BulkAppointmentUploadService.new(program, vip, invalid_file)
        expect(service.call).to be false
        expect(service.errors).to include("Invalid file type. Please upload a CSV or Excel file.")
      end
    end

    context 'with valid CSV file' do
      let(:csv_content) do
        "Start Time,End Time\n" \
        "#{(Time.current + 1.hour).strftime('%m/%d/%Y %H:%M')},#{(Time.current + 2.hours).strftime('%m/%d/%Y %H:%M')}\n" \
        "#{(Time.current + 3.hours).strftime('%m/%d/%Y %H:%M')},#{(Time.current + 4.hours).strftime('%m/%d/%Y %H:%M')}\n"
      end
      let(:csv_file) { Tempfile.new([ 'appointments', '.csv' ]) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('appointments.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'processes valid rows and creates appointments' do
        service = BulkAppointmentUploadService.new(program, vip, file)
        expect {
          service.call
        }.to change { Appointment.count }.by(2)
        expect(service.success_count).to eq(2)
        expect(service.failure_count).to eq(0)
      end

      it 'returns true when at least one appointment is created' do
        service = BulkAppointmentUploadService.new(program, vip, file)
        expect(service.call).to be true
      end
    end

    context 'with valid Excel file' do
      let(:xlsx_file) { Tempfile.new([ 'appointments', '.xlsx' ]) }

      before do
        # Mock the file and Roo::Excelx behavior
        allow(file).to receive(:original_filename).and_return('appointments.xlsx')
        allow(file).to receive(:path).and_return(xlsx_file.path)
      end

      after do
        xlsx_file.close
        xlsx_file.unlink if File.exist?(xlsx_file.path)
      end

      it 'handles Excel files' do
        # Mock Roo::Excelx to return a spreadsheet-like object
        spreadsheet = double('spreadsheet')
        allow(spreadsheet).to receive(:last_row).and_return(2)
        allow(spreadsheet).to receive(:row).with(2).and_return([
          (Time.current + 1.hour).strftime('%m/%d/%Y %H:%M'),
          (Time.current + 2.hours).strftime('%m/%d/%Y %H:%M')
        ])
        allow(Roo::Excelx).to receive(:new).and_return(spreadsheet)

        service = BulkAppointmentUploadService.new(program, vip, file)
        expect(service.call).to be true
      end
    end

    context 'with invalid rows' do
      let(:csv_content) do
        "Start Time,End Time\n" \
        "invalid,invalid\n" \
        ",#{(Time.current + 2.hours).strftime('%m/%d/%Y %H:%M')}\n"
      end
      let(:csv_file) { Tempfile.new([ 'appointments', '.csv' ]) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('appointments.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'tracks failures and errors' do
        service = BulkAppointmentUploadService.new(program, vip, file)
        service.call
        expect(service.failure_count).to be > 0
        expect(service.errors).not_to be_empty
      end

      it 'returns false when no appointments are created' do
        service = BulkAppointmentUploadService.new(program, vip, file)
        expect(service.call).to be false
      end
    end

    context 'with file reading errors' do
      before do
        allow(file).to receive(:original_filename).and_return('appointments.csv')
        allow(file).to receive(:path).and_return('/nonexistent/path.csv')
      end

      it 'handles file reading errors gracefully' do
        service = BulkAppointmentUploadService.new(program, vip, file)
        expect(service.call).to be false
        expect(service.errors).not_to be_empty
      end
    end
  end

  describe 'private methods' do
    let(:service) { BulkAppointmentUploadService.new(program, vip, file) }

    describe '#parse_datetime' do
      it 'parses various datetime formats' do
        time = Time.current
        formats = [
          time.to_s,
          time.strftime('%m/%d/%Y %H:%M'),
          time.strftime('%Y-%m-%d %H:%M'),
          time.strftime('%m/%d/%Y %I:%M %p')
        ]

        formats.each do |format|
          parsed = service.send(:parse_datetime, format)
          expect(parsed).to be_a(Time).or be_a(DateTime)
        end
      end

      it 'returns nil for invalid datetime strings' do
        expect(service.send(:parse_datetime, 'invalid')).to be_nil
      end
    end
  end
end
