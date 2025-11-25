require 'rails_helper'

RSpec.describe BulkFacultyUploadService, type: :service do
  let(:department) { Department.create!(name: "Test Department") }
  let(:file) { double('file', original_filename: 'faculty.csv', path: '/tmp/faculty.csv') }

  describe '#initialize' do
    it 'sets department and file' do
      service = BulkFacultyUploadService.new(department, file)
      expect(service.department).to eq(department)
      expect(service.file).to eq(file)
    end

    it 'initializes errors, success_count, and failure_count' do
      service = BulkFacultyUploadService.new(department, file)
      expect(service.errors).to eq([])
      expect(service.success_count).to eq(0)
      expect(service.failure_count).to eq(0)
    end
  end

  describe '#call' do
    context 'with invalid file' do
      it 'returns false when file is nil' do
        service = BulkFacultyUploadService.new(department, nil)
        expect(service.call).to be false
        expect(service.errors).to include("No file provided")
      end

      it 'returns false when file type is invalid' do
        invalid_file = double('file', original_filename: 'faculty.txt')
        service = BulkFacultyUploadService.new(department, invalid_file)
        expect(service.call).to be false
        expect(service.errors).to include("Invalid file type. Please upload a CSV or Excel file.")
      end
    end

    context 'with valid CSV file' do
      let(:csv_content) do
        "Name,Profile URL,Title,Ranking\n" \
        "Dr. Smith,http://example.com/smith,Professor,1\n" \
        "Dr. Jones,http://example.com/jones,Associate Professor,2\n"
      end
      let(:csv_file) { Tempfile.new(['faculty', '.csv']) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('faculty.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'creates new VIPs' do
        service = BulkFacultyUploadService.new(department, file)
        expect {
          service.call
        }.to change { Vip.count }.by(2)
        expect(service.success_count).to eq(2)
      end

      it 'sets VIP attributes correctly' do
        service = BulkFacultyUploadService.new(department, file)
        service.call
        vip = Vip.find_by(name: "Dr. Smith")
        expect(vip.profile_url).to eq("http://example.com/smith")
        expect(vip.title).to eq("Professor")
        expect(vip.ranking).to eq(1)
      end

      it 'returns true when at least one VIP is created' do
        service = BulkFacultyUploadService.new(department, file)
        expect(service.call).to be true
      end
    end

    context 'with existing VIPs' do
      let!(:existing_vip) { Vip.create!(name: "Dr. Smith", department: department) }
      let(:csv_content) do
        "Name,Profile URL,Title,Ranking\n" \
        "Dr. Smith,http://example.com/smith,Updated Title,5\n" \
        "Dr. New,http://example.com/new,Professor,1\n"
      end
      let(:csv_file) { Tempfile.new(['faculty', '.csv']) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('faculty.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'updates existing VIPs' do
        service = BulkFacultyUploadService.new(department, file)
        service.call
        expect(existing_vip.reload.title).to eq("Updated Title")
        expect(existing_vip.ranking).to eq(5)
      end

      it 'creates new VIPs' do
        service = BulkFacultyUploadService.new(department, file)
        expect {
          service.call
        }.to change { Vip.count }.by(1) # Only creates the new VIP
      end
    end

    context 'with invalid rows' do
      let(:csv_content) do
        "Name,Profile URL,Title,Ranking\n" \
        ",http://example.com/smith,Professor,1\n"
      end
      let(:csv_file) { Tempfile.new(['faculty', '.csv']) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('faculty.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'skips rows with blank names' do
        service = BulkFacultyUploadService.new(department, file)
        service.call
        expect(Vip.where(name: '')).to be_empty
      end
    end

    context 'with ranking values' do
      let(:csv_content) do
        "Name,Profile URL,Title,Ranking\n" \
        "Dr. Smith,http://example.com/smith,Professor,\n" \
        "Dr. Jones,http://example.com/jones,Professor,abc\n"
      end
      let(:csv_file) { Tempfile.new(['faculty', '.csv']) }

      before do
        csv_file.write(csv_content)
        csv_file.rewind
        allow(file).to receive(:original_filename).and_return('faculty.csv')
        allow(file).to receive(:path).and_return(csv_file.path)
      end

      after do
        csv_file.close
        csv_file.unlink
      end

      it 'defaults ranking to 0 when blank or invalid' do
        service = BulkFacultyUploadService.new(department, file)
        service.call
        vip1 = Vip.find_by(name: "Dr. Smith")
        vip2 = Vip.find_by(name: "Dr. Jones")
        expect(vip1.ranking).to eq(0)
        expect(vip2.ranking).to eq(0)
      end
    end
  end
end
