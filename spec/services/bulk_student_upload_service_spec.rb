require 'rails_helper'

RSpec.describe BulkStudentUploadService, type: :service do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }
  let(:file) { double('file', original_filename: 'students.csv', path: '/tmp/students.csv') }

  describe '#initialize' do
    it 'sets program and file' do
      service = BulkStudentUploadService.new(program, file)
      expect(service.program).to eq(program)
      expect(service.file).to eq(file)
    end

    it 'initializes errors, success_count, and failure_count' do
      service = BulkStudentUploadService.new(program, file)
      expect(service.errors).to eq([])
      expect(service.success_count).to eq(0)
      expect(service.failure_count).to eq(0)
    end
  end

  describe '#call' do
    context 'with invalid file' do
      it 'returns false when file is nil' do
        service = BulkStudentUploadService.new(program, nil)
        expect(service.call).to be false
        expect(service.errors).to include("No file provided")
      end

      it 'returns false when file type is invalid' do
        invalid_file = double('file', original_filename: 'students.txt')
        service = BulkStudentUploadService.new(program, invalid_file)
        expect(service.call).to be false
        expect(service.errors).to include("Invalid file type. Please upload a CSV or Excel file.")
      end
    end

    context 'with valid CSV file' do
      let(:csv_content) do
        "Email,Last Name,First Name,UMID\n" \
        "student1@example.com,Smith,John,12345678\n" \
        "student2@example.com,Jones,Jane,87654321\n"
      end
      let(:csv_file) { Tempfile.new([ 'students', '.csv' ]) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('students.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'creates new users and enrolls them in the program' do
        service = BulkStudentUploadService.new(program, file)
        expect {
          service.call
        }.to change { User.count }.by(2)
          .and change { StudentProgram.count }.by(2)
        expect(service.success_count).to eq(2)
      end

      it 'adds student role to new users' do
        service = BulkStudentUploadService.new(program, file)
        service.call
        users = User.where(email_address: [ 'student1@example.com', 'student2@example.com' ])
        users.each do |user|
          expect(user.student?).to be true
        end
      end

      it 'sets must_change_password for new users' do
        service = BulkStudentUploadService.new(program, file)
        service.call
        user = User.find_by(email_address: 'student1@example.com')
        expect(user.must_change_password).to be true
      end

      it 'returns true when at least one student is enrolled' do
        service = BulkStudentUploadService.new(program, file)
        expect(service.call).to be true
      end
    end

    context 'with existing users' do
      let!(:existing_user) { User.create!(email_address: 'existing@example.com', password: 'password123') }
      let(:csv_content) do
        "Email,Last Name,First Name,UMID\n" \
        "existing@example.com,Updated,Name,12345678\n" \
        "new@example.com,New,User,87654321\n"
      end
      let(:csv_file) { Tempfile.new([ 'students', '.csv' ]) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('students.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'updates existing users without creating duplicates' do
        service = BulkStudentUploadService.new(program, file)
        expect {
          service.call
        }.to change { User.count }.by(1) # Only creates the new user
        expect(existing_user.reload.last_name).to eq('Updated')
      end

      it 'enrolls existing users in the program' do
        service = BulkStudentUploadService.new(program, file)
        service.call
        expect(existing_user.enrolled_in_program?(program)).to be true
      end
    end

    context 'with invalid rows' do
      let(:csv_content) do
        "Email,Last Name,First Name,UMID\n" \
        ",Smith,John,12345678\n" \
        "invalid-email,Jones,Jane,87654321\n"
      end
      let(:csv_file) { Tempfile.new([ 'students', '.csv' ]) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('students.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'skips rows with blank emails' do
        service = BulkStudentUploadService.new(program, file)
        service.call
        expect(User.where(email_address: '')).to be_empty
      end
    end

    describe '#format_umid' do
      let(:service) { BulkStudentUploadService.new(program, file) }

      it 'formats numeric UMIDs as 8-digit strings' do
        expect(service.send(:format_umid, 1234567)).to eq('01234567')
        expect(service.send(:format_umid, '1234567')).to eq('01234567')
        expect(service.send(:format_umid, 12345678)).to eq('12345678')
      end

      it 'handles float values' do
        expect(service.send(:format_umid, 1234567.0)).to eq('01234567')
      end

      it 'returns string as-is for non-numeric values' do
        expect(service.send(:format_umid, 'ABC12345')).to eq('ABC12345')
      end

      it 'returns nil for nil values' do
        expect(service.send(:format_umid, nil)).to be_nil
      end

      it 'strips whitespace' do
        expect(service.send(:format_umid, ' 12345678 ')).to eq('12345678')
      end
    end
  end
end
