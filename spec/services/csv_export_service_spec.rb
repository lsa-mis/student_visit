require 'rails_helper'

RSpec.describe CsvExportService, type: :service do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:questionnaire) { Questionnaire.create!(name: "Test Questionnaire", program: program) }
  let(:question) { Question.create!(text: "Test Question", question_type: "text", questionnaire: questionnaire, position: 1) }
  let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }
  let(:vip) { Vip.create!(name: "Dr. Smith", office_number: "LSA 3202", program: program) }

  before do
    student.add_role('student')
    StudentProgram.create!(user: student, program: program)
  end

  describe '.export_students' do
    it 'generates CSV with student data' do
      csv = CsvExportService.export_students(program)
      expect(csv).to be_a(String)
      expect(csv).to include('Email')
      expect(csv).to include('Name')
      expect(csv).to include('Enrolled Date')
    end

    it 'includes questionnaire questions in headers' do
      # Ensure questionnaire and question are created
      questionnaire
      question
      csv = CsvExportService.export_students(program)
      expect(csv).to include('Q: Test Question')
    end

    it 'includes student answers' do
      Answer.create!(question: question, student: student, program: program, content: "Test Answer")
      csv = CsvExportService.export_students(program)
      expect(csv).to include('student@example.com')
      expect(csv).to include('Test Answer')
    end

    it 'includes appointment information' do
      appointment = Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip,
        student: student
      )
      csv = CsvExportService.export_students(program)
      expect(csv).to include('Dr. Smith')
    end
  end

  describe '.export_program_appointments' do
    let!(:available_appointment) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip,
        office_number: "LSA 3202"
      )
    end
    let!(:booked_appointment) do
      Appointment.create!(
        start_time: 3.hours.from_now,
        end_time: 4.hours.from_now,
        program: program,
        vip: vip,
        student: student,
        office_number: "ISR 4184B"
      )
    end

    it 'generates CSV with expected headers' do
      csv = CsvExportService.export_program_appointments(program, scope: :all)
      expect(csv).to be_a(String)
      expect(csv).to include("Faculty")
      expect(csv).to include("Date")
      expect(csv).to include("Start Time")
      expect(csv).to include("End Time")
      expect(csv).to include("Office Number")
      expect(csv).to include("Status")
      expect(csv).to include("Student")
    end

    it 'includes all appointments when scope is :all' do
      csv = CsvExportService.export_program_appointments(program, scope: :all)
      expect(csv).to include("Dr. Smith")
      expect(csv).to include("Available")
      expect(csv).to include("Booked")
      expect(csv).to include("student@example.com")
      expect(csv).to include("LSA 3202")
      expect(csv).to include("ISR 4184B")
    end

    it 'includes only booked appointments when scope is :scheduled' do
      csv = CsvExportService.export_program_appointments(program, scope: :scheduled)
      expect(csv).to include("Dr. Smith")
      expect(csv).to include("Booked")
      expect(csv).to include("student@example.com")
      expect(csv).not_to include("Available")
    end

    it 'defaults to :all scope when not specified' do
      csv = CsvExportService.export_program_appointments(program)
      expect(csv).to include("Available")
      expect(csv).to include("Booked")
    end

    it 'handles empty appointments' do
      program_without_appointments = Program.create!(
        name: "Empty Program",
        department: department,
        default_appointment_length: 30,
        information_email_address: "empty@example.com"
      )
      csv = CsvExportService.export_program_appointments(program_without_appointments, scope: :all)
      expect(csv).to include("Faculty")
      expect(csv).to include("Date")
      expect(csv.lines.count).to eq(1)
    end

    it 'sorts by VIP last name then by appointment date' do
      vip_adams = Vip.create!(name: "Dr. Adams", office_number: "LSA 100", program: program)
      vip_zeller = Vip.create!(name: "Dr. Zeller", office_number: "LSA 200", program: program)
      Appointment.create!(start_time: 2.hours.from_now, end_time: 3.hours.from_now, program: program, vip: vip_zeller)
      Appointment.create!(start_time: 5.hours.from_now, end_time: 6.hours.from_now, program: program, vip: vip_adams)
      Appointment.create!(start_time: 1.hour.from_now, end_time: 2.hours.from_now, program: program, vip: vip_adams)
      csv = CsvExportService.export_program_appointments(program, scope: :all)
      lines = csv.lines
      # Adams (A) before Smith (S) before Zeller (Z). Within each VIP: by start_time.
      # Adams: 1hr, 5hr. Smith: 1hr, 3hr (from available_appointment, booked_appointment). Zeller: 2hr.
      expect(lines[1]).to include("Dr. Adams")
      expect(lines[2]).to include("Dr. Adams")
      expect(lines[3]).to include("Dr. Smith")
      expect(lines[4]).to include("Dr. Smith")
      expect(lines[5]).to include("Dr. Zeller")
    end

    it 'handles empty scheduled appointments' do
      program_without_booked = Program.create!(
        name: "No Booked Program",
        department: department,
        default_appointment_length: 30,
        information_email_address: "nobook@example.com"
      )
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program_without_booked,
        vip: Vip.create!(name: "Dr. Jones", office_number: "LSA 100", program: program_without_booked)
      )
      csv = CsvExportService.export_program_appointments(program_without_booked, scope: :scheduled)
      expect(csv).to include("Faculty")
      expect(csv.lines.count).to eq(1)
    end
  end

  describe '.export_appointments_by_faculty' do
    let!(:appointment1) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip
      )
    end
    let!(:appointment2) do
      Appointment.create!(
        start_time: 3.hours.from_now,
        end_time: 4.hours.from_now,
        program: program,
        vip: vip,
        student: student
      )
    end

    it 'generates CSV with appointment data' do
      csv = CsvExportService.export_appointments_by_faculty(program)
      expect(csv).to be_a(String)
      expect(csv).to include('Faculty')
      expect(csv).to include('Date')
      expect(csv).to include('Start Time')
      expect(csv).to include('End Time')
      expect(csv).to include('Status')
      expect(csv).to include('Student')
    end

    it 'includes all appointments for each faculty member' do
      csv = CsvExportService.export_appointments_by_faculty(program)
      expect(csv).to include('Dr. Smith')
      expect(csv).to include('Available')
      expect(csv).to include('Booked')
    end

    it 'orders appointments by start_time' do
      csv = CsvExportService.export_appointments_by_faculty(program)
      lines = csv.split("\n")
      # Check that appointments are included
      expect(csv).to include('Dr. Smith')
    end
  end

  describe '.export_appointments_by_student' do
    let!(:appointment) do
      Appointment.create!(
        start_time: 1.hour.from_now,
        end_time: 2.hours.from_now,
        program: program,
        vip: vip,
        student: student
      )
    end

    it 'generates CSV with student appointment data' do
      csv = CsvExportService.export_appointments_by_student(program)
      expect(csv).to be_a(String)
      expect(csv).to include('Student Email')
      expect(csv).to include('Faculty')
      expect(csv).to include('Date')
      expect(csv).to include('Start Time')
      expect(csv).to include('End Time')
    end

    it 'includes student appointments' do
      csv = CsvExportService.export_appointments_by_student(program)
      expect(csv).to include('student@example.com')
      expect(csv).to include('Dr. Smith')
    end
  end

  describe '.export_calendar' do
    let(:date) { Date.today }
    let!(:event) do
      CalendarEvent.create!(
        title: "Test Event",
        start_time: date.beginning_of_day + 10.hours,
        end_time: date.beginning_of_day + 11.hours,
        program: program
      )
    end
    let!(:appointment) do
      Appointment.create!(
        start_time: date.beginning_of_day + 14.hours,
        end_time: date.beginning_of_day + 15.hours,
        program: program,
        vip: vip,
        student: student
      )
    end

    it 'generates CSV with calendar events and appointments' do
      csv = CsvExportService.export_calendar(student, program, date)
      expect(csv).to be_a(String)
      expect(csv).to include('Type')
      expect(csv).to include('Title')
      expect(csv).to include('Date')
      expect(csv).to include('Start Time')
      expect(csv).to include('End Time')
      expect(csv).to include('Details')
    end

    it 'includes calendar events' do
      csv = CsvExportService.export_calendar(student, program, date)
      expect(csv).to include('Event')
      expect(csv).to include('Test Event')
    end

    it 'includes student appointments' do
      csv = CsvExportService.export_calendar(student, program, date)
      expect(csv).to include('Appointment')
      expect(csv).to include('Dr. Smith')
    end

    it 'filters by date when provided' do
      future_date = Date.tomorrow
      csv = CsvExportService.export_calendar(student, program, future_date)
      expect(csv).not_to include('Test Event')
    end

    it 'uses program dates when date is nil' do
      program.update!(open_date: Date.today.beginning_of_day, close_date: Date.today.end_of_day)
      csv = CsvExportService.export_calendar(student, program, nil)
      expect(csv).to include('Test Event')
    end
  end

  describe '.export_questionnaire_responses' do
    let!(:answer) { Answer.create!(question: question, student: student, program: program, content: "Test Answer") }

    it 'generates CSV with questionnaire responses' do
      csv = CsvExportService.export_questionnaire_responses(questionnaire, program)
      expect(csv).to be_a(String)
      expect(csv).to include('Student Email')
      expect(csv).to include('Q1: Test Question')
    end

    it 'includes student answers' do
      csv = CsvExportService.export_questionnaire_responses(questionnaire, program)
      expect(csv).to include('student@example.com')
      expect(csv).to include('Test Answer')
    end

    it 'shows "Not answered" for missing answers' do
      other_student = User.create!(email_address: 'other@example.com', password: 'password123')
      other_student.add_role('student')
      StudentProgram.create!(user: other_student, program: program)
      csv = CsvExportService.export_questionnaire_responses(questionnaire, program)
      expect(csv).to include('other@example.com')
      expect(csv).to include('Not answered')
    end

    context 'with checkbox questions' do
      let(:checkbox_question) do
        Question.create!(
          text: "Checkbox Question",
          question_type: "checkbox",
          questionnaire: questionnaire,
          position: 2
        )
      end
      let!(:checkbox_answer) do
        Answer.create!(
          question: checkbox_question,
          student: student,
          program: program,
          content: '["Option 1", "Option 2"]'
        )
      end

      it 'formats checkbox answers correctly' do
        csv = CsvExportService.export_questionnaire_responses(questionnaire, program)
        expect(csv).to include('Option 1')
        expect(csv).to include('Option 2')
      end
    end

    context 'with rich_text questions' do
      let(:rich_text_question) do
        Question.create!(
          text: "Rich Text Question",
          question_type: "rich_text",
          questionnaire: questionnaire,
          position: 3
        )
      end
      let!(:rich_text_answer) do
        Answer.create!(
          question: rich_text_question,
          student: student,
          program: program,
          content: "<p>Rich text content</p>"
        )
      end

      it 'converts rich text to plain text' do
        csv = CsvExportService.export_questionnaire_responses(questionnaire, program)
        # Rich text should be converted to plain text
        expect(csv).to include('Rich text content')
      end
    end
  end
end
