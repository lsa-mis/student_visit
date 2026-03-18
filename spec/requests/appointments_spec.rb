require 'rails_helper'

RSpec.describe "Appointments", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }
  let(:vip) { Vip.create!(name: "Dr. Smith", office_number: "LSA 3202", program: program) }
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

      it "displays appointments and actions" do
        appointment
        get department_program_appointments_path(department, program)
        expect(response.body).to include("Dr. Smith")
        expect(response.body).to include("View")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_program_appointments_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "shows actions column" do
        appointment
        get department_program_appointments_path(department, program)
        expect(response.body).to include("Actions")
        expect(response.body).to include("View")
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

  describe "GET /departments/:department_id/programs/:program_id/appointments/export" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns CSV attachment with all appointments" do
        appointment
        get export_department_program_appointments_path(department, program, scope: "all", format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("appointments")
        expect(response.body).to include("Faculty")
        expect(response.body).to include("Office Number")
        expect(response.body).to include("Dr. Smith")
      end

      it "returns CSV with only scheduled appointments when scope is scheduled" do
        available_apt = Appointment.create!(
          start_time: 1.hour.from_now,
          end_time: 2.hours.from_now,
          program: program,
          vip: vip
        )
        booked_apt = Appointment.create!(
          start_time: 3.hours.from_now,
          end_time: 4.hours.from_now,
          program: program,
          vip: vip,
          student: student
        )
        get export_department_program_appointments_path(department, program, scope: "scheduled", format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Booked")
        expect(response.body).to include("student@example.com")
      end

      it "returns CSV with headers when no appointments exist" do
        get export_department_program_appointments_path(department, program, scope: "all", format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Faculty")
        expect(response.body).to include("Date")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns CSV attachment" do
        get export_department_program_appointments_path(department, program, scope: "all", format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/csv")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get export_department_program_appointments_path(department, program, scope: "all", format: :csv)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as student" do
      before { sign_in_as_student }

      it "redirects with authorization error" do
        get export_department_program_appointments_path(department, program, scope: "all", format: :csv)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("not authorized")
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

  describe "DELETE /departments/:department_id/programs/:program_id/appointments/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the appointment" do
        appointment # create it
        expect {
          delete department_program_appointment_path(department, program, appointment)
        }.to change { Appointment.count }.by(-1)
        expect(response).to redirect_to(department_program_appointments_path(department, program))
        expect(flash[:notice]).to include("successfully deleted")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "deletes the appointment" do
        appointment
        expect {
          delete department_program_appointment_path(department, program, appointment)
        }.to change { Appointment.count }.by(-1)
        expect(response).to redirect_to(department_program_appointments_path(department, program))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_appointment_path(department, program, appointment)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_appointment_path(department, program)
        expect(response).to have_http_status(:success)
      end

      it "displays office_number field" do
        get new_department_program_appointment_path(department, program)
        expect(response.body).to include("Office Number")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_appointment_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/appointments" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates an appointment with office_number from VIP" do
        expect {
          post department_program_appointments_path(department, program), params: {
            appointment: {
              vip_id: vip.id,
              start_time: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M"),
              end_time: 2.hours.from_now.strftime("%Y-%m-%dT%H:%M")
            }
          }
        }.to change { Appointment.count }.by(1)
        created_appointment = Appointment.last
        expect(created_appointment.office_number).to eq("LSA 3202")
        expect(response).to redirect_to(department_program_appointments_path(department, program))
      end

      it "creates an appointment with custom office_number" do
        expect {
          post department_program_appointments_path(department, program), params: {
            appointment: {
              vip_id: vip.id,
              start_time: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M"),
              end_time: 2.hours.from_now.strftime("%Y-%m-%dT%H:%M"),
              office_number: "ISR 4184B"
            }
          }
        }.to change { Appointment.count }.by(1)
        created_appointment = Appointment.last
        expect(created_appointment.office_number).to eq("ISR 4184B")
      end

      it "allows appointment to have different office_number than VIP" do
        post department_program_appointments_path(department, program), params: {
          appointment: {
            vip_id: vip.id,
            start_time: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M"),
            end_time: 2.hours.from_now.strftime("%Y-%m-%dT%H:%M"),
            office_number: "Different Location"
          }
        }
        created_appointment = Appointment.last
        expect(created_appointment.office_number).to eq("Different Location")
        expect(created_appointment.vip.office_number).to eq("LSA 3202")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_program_appointments_path(department, program), params: {
          appointment: {
            vip_id: vip.id,
            start_time: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M"),
            end_time: 2.hours.from_now.strftime("%Y-%m-%dT%H:%M")
          }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:program_id/appointments/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_appointment_path(department, program, appointment)
        expect(response).to have_http_status(:success)
      end

      it "displays office_number field with current value" do
        appointment.update!(office_number: "ISR 4184B")
        get edit_department_program_appointment_path(department, program, appointment)
        expect(response.body).to include("Office Number")
        expect(response.body).to include("ISR 4184B")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_appointment_path(department, program, appointment)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:program_id/appointments/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the appointment office_number" do
        patch department_program_appointment_path(department, program, appointment), params: {
          appointment: {
            office_number: "ISR 4184B"
          }
        }
        expect(response).to redirect_to(department_program_appointment_path(department, program, appointment))
        expect(appointment.reload.office_number).to eq("ISR 4184B")
      end

      it "updates office_number independently of VIP" do
        appointment.update!(office_number: "LSA 3202")
        patch department_program_appointment_path(department, program, appointment), params: {
          appointment: {
            office_number: "Custom Meeting Room"
          }
        }
        expect(appointment.reload.office_number).to eq("Custom Meeting Room")
        expect(appointment.vip.office_number).to eq("LSA 3202")
      end

      it "allows clearing office_number" do
        appointment.update!(office_number: "LSA 3202")
        patch department_program_appointment_path(department, program, appointment), params: {
          appointment: {
            office_number: ""
          }
        }
        expect(response).to redirect_to(department_program_appointment_path(department, program, appointment))
        # set_office_number_from_vip runs only on create, so update preserves the cleared value
        expect(appointment.reload.office_number).to be_blank
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_appointment_path(department, program, appointment), params: {
          appointment: { office_number: "ISR 4184B" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs/:program_id/appointments/:id/release" do
    let!(:booked_appointment) do
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

      it "releases the student reservation and keeps the appointment" do
        expect {
          post release_department_program_appointment_path(department, program, booked_appointment)
        }.not_to change { Appointment.count }

        expect(booked_appointment.reload.student).to be_nil
        expect(response).to redirect_to(department_program_appointment_path(department, program, booked_appointment))
        expect(flash[:notice]).to include("cancelled")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "releases the student reservation" do
        post release_department_program_appointment_path(department, program, booked_appointment)
        expect(booked_appointment.reload.student).to be_nil
        expect(response).to redirect_to(department_program_appointment_path(department, program, booked_appointment))
      end
    end

    context "when appointment is already available" do
      before { sign_in_as_department_admin(department) }

      it "does not change the appointment and shows an alert" do
        booked_appointment.update!(student: nil)

        expect {
          post release_department_program_appointment_path(department, program, booked_appointment)
        }.not_to change { booked_appointment.reload.student }

        expect(response).to redirect_to(department_program_appointment_path(department, program, booked_appointment))
        expect(flash[:alert]).to include("Unable to cancel reservation")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post release_department_program_appointment_path(department, program, booked_appointment)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "Buttons on appointment show page" do
    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "shows Delete Appointment button" do
        get department_program_appointment_path(department, program, appointment)
        expect(response.body).to include("Delete Appointment")
      end

      it "shows Cancel Reservation button when appointment is booked" do
        appointment.update!(student: student)
        get department_program_appointment_path(department, program, appointment)
        expect(response.body).to include("Cancel Reservation")
      end

      it "does not show Cancel Reservation button when appointment is available" do
        get department_program_appointment_path(department, program, appointment)
        expect(response.body).not_to include("Cancel Reservation")
      end
    end
  end
end
