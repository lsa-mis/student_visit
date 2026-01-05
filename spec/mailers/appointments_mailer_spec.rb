require 'rails_helper'

RSpec.describe AppointmentsMailer, type: :mailer do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
  let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }
  let(:appointment) do
    Appointment.create!(
      start_time: 1.hour.from_now,
      end_time: 2.hours.from_now,
      program: program,
      vip: vip,
      student: student
    )
  end

  describe '#change_notification' do
    context 'when action is "selected"' do
      let(:mail) { AppointmentsMailer.change_notification(student, appointment, 'selected') }

      it 'renders the headers' do
        expect(mail.subject).to eq("Appointment Confirmed: Dr. Smith")
        expect(mail.to).to eq([ student.email_address ])
        expect(mail.from).to be_present
      end

      it 'renders the body' do
        expect(mail.body.encoded).to include('Dr. Smith')
        expect(mail.body.encoded).to include('Confirmed')
      end

      it 'assigns instance variables' do
        expect(mail.body.encoded).to include(student.email_address)
        expect(mail.body.encoded).to include(program.name)
      end
    end

    context 'when action is "deleted"' do
      let(:mail) { AppointmentsMailer.change_notification(student, appointment, 'deleted') }

      it 'renders the headers' do
        expect(mail.subject).to eq("Appointment Cancelled: Dr. Smith")
        expect(mail.to).to eq([ student.email_address ])
      end

      it 'renders the body' do
        expect(mail.body.encoded).to include('Dr. Smith')
        expect(mail.body.encoded).to include('Cancelled')
      end
    end
  end
end
