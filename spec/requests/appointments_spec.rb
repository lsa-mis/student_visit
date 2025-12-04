require 'rails_helper'

RSpec.describe "Appointments", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30) }
  let(:vip) { Vip.create!(name: "Dr. Smith", program: program) }
  let(:student) { User.create!(email_address: 'student@example.com', password: 'password123') }
  let(:appointment) do
    Appointment.create!(
      start_time: 1.hour.from_now,
      end_time: 2.hours.from_now,
      program: program,
      vip: vip
    )
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays appointments" do
        appointment
        get department_program_appointments_path(department, program)
        expect(response.body).to include("Dr. Smith")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_appointments_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as student" do
      before { sign_in_as_student }

      it "redirects with authorization error" do
        get department_program_appointments_path(department, program)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_appointment_path(department, program, appointment)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_appointment_path(department, program, appointment)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_appointment_path(department, program, appointment)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments/bulk_upload" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get bulk_upload_department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays VIPs" do
        vip
        get bulk_upload_department_program_appointments_path(department, program)
        expect(response.body).to include("Dr. Smith")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get bulk_upload_department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get bulk_upload_department_program_appointments_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/appointments/process_bulk_upload" do
    let(:csv_file) { fixture_file_upload('appointments.csv', 'text/csv') }

    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      context "with valid file and VIP" do
        it "processes the upload" do
          # Create a temporary CSV file
          csv_content = "Start Time,End Time\n#{(Time.current + 1.hour).strftime('%m/%d/%Y %H:%M')},#{(Time.current + 2.hours).strftime('%m/%d/%Y %H:%M')}\n"
          file = Tempfile.new([ 'appointments', '.csv' ])
          file.write(csv_content)
          file.rewind

          uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

          post process_bulk_upload_department_program_appointments_path(department, program),
            params: { file: uploaded_file, vip_id: vip.id }

          file.close
          file.unlink

          expect(response).to redirect_to(department_program_appointments_path(department, program))
        end
      end

      context "without file" do
        it "redirects with alert" do
          post process_bulk_upload_department_program_appointments_path(department, program),
            params: { vip_id: vip.id }
          expect(response).to redirect_to(bulk_upload_department_program_appointments_path(department, program))
          expect(flash[:alert]).to include("Please select a file and VIP")
        end
      end

      context "without VIP" do
        it "redirects with alert" do
          csv_content = "Start Time,End Time\n"
          file = Tempfile.new([ 'appointments', '.csv' ])
          file.write(csv_content)
          file.rewind

          uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/csv')

          post process_bulk_upload_department_program_appointments_path(department, program),
            params: { file: uploaded_file }

          file.close
          file.unlink

          expect(response).to redirect_to(bulk_upload_department_program_appointments_path(department, program))
          expect(flash[:alert]).to include("Please select a file and VIP")
        end
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post process_bulk_upload_department_program_appointments_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments/by_faculty" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get by_faculty_department_program_appointments_path(department, program, vip_id: vip.id)
        expect(response).to have_http_status(:success)
      end

      it "displays appointments for the VIP" do
        appointment
        get by_faculty_department_program_appointments_path(department, program, vip_id: vip.id)
        expect(response.body).to include("Dr. Smith")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get by_faculty_department_program_appointments_path(department, program, vip_id: vip.id)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments/by_student" do
    let(:booked_appointment) do
      Appointment.create!(
        start_time: 3.hours.from_now,
        end_time: 4.hours.from_now,
        program: program,
        vip: vip,
        student: student
      )
    end

    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get by_student_department_program_appointments_path(department, program, student_id: student.id)
        expect(response).to have_http_status(:success)
      end

      it "displays appointments for the student" do
        booked_appointment
        get by_student_department_program_appointments_path(department, program, student_id: student.id)
        expect(response.body).to include("student@example.com")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get by_student_department_program_appointments_path(department, program, student_id: student.id)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
