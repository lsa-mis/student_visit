require 'rails_helper'

RSpec.describe "Student::Dashboard", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, active: true) }
  let(:student_user) { User.create!(email_address: "student#{SecureRandom.hex(4)}@example.com", password: 'password123') }

  before do
    department.update!(active_program: program)
    student_user.add_role('student')
    StudentProgram.create!(user: student_user, program: program) if program
  end

  describe "GET /student/dashboard" do
    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "returns http success" do
        get student_dashboard_path
        expect(response).to have_http_status(:success)
      end

      context "with single enrolled department" do
        it "automatically selects the department" do
          get student_dashboard_path
          expect(session[:selected_department_id]).to eq(department.id)
        end
      end

      context "with multiple enrolled departments" do
        let(:department2) { Department.create!(name: "Second Department") }
        let(:program2) { Program.create!(name: "Second Program", department: department2, default_appointment_length: 30, active: true) }

        before do
          department2.update!(active_program: program2)
          StudentProgram.create!(user: student_user, program: program2)
        end

        it "shows department selection" do
          get student_dashboard_path
          expect(response.body).to include("Select Department")
        end

        it "does not auto-select when multiple departments exist" do
          get student_dashboard_path
          expect(session[:selected_department_id]).to be_nil
        end
      end

      context "with selected department" do
        before do
          # Set the session by making a POST request to select_department
          post select_department_student_dashboard_path, params: { department_id: department.id }
        end

        it "displays the selected department" do
          get student_dashboard_path
          expect(response.body).to include(department.name)
        end

        it "displays the active program" do
          get student_dashboard_path
          expect(response.body).to include(program.name)
        end

        it "shows navigation links" do
          get student_dashboard_path
          expect(response.body).to include("Questionnaires")
          expect(response.body).to include("Appointments")
          expect(response.body).to include("Calendar")
          expect(response.body).to include("Map")
        end
      end

      context "with department but no active program" do
        let(:inactive_program) { Program.create!(name: "Inactive Program", department: department, default_appointment_length: 30, active: false) }

        before do
          department.update!(active_program: nil)
          # Set the session by making a POST request to select_department
          post select_department_student_dashboard_path, params: { department_id: department.id }
        end

        it "shows no active program message" do
          get student_dashboard_path
          expect(response.body).to include("No active program found")
        end
      end

      context "without selected department" do
        let(:department2) { Department.create!(name: "Second Department") }
        let(:program2) { Program.create!(name: "Second Program", department: department2, default_appointment_length: 30, active: true) }

        before do
          # Ensure session is cleared by having multiple departments
          # When there are multiple departments, the session won't be auto-set
          department2.update!(active_program: program2)
          StudentProgram.create!(user: student_user, program: program2)
        end

        it "shows department selection prompt" do
          get student_dashboard_path
          expect(response.body).to include("Please select a department")
        end
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get student_dashboard_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated as non-student" do
      before { sign_in_as_super_admin }

      it "redirects or denies access" do
        get student_dashboard_path
        expect(response).to have_http_status(:redirect).or have_http_status(:forbidden)
      end
    end
  end

  describe "POST /student/dashboard/select_department" do
    let(:department2) { Department.create!(name: "Second Department") }
    let(:program2) { Program.create!(name: "Second Program", department: department2, default_appointment_length: 30, active: true) }

    before do
      department2.update!(active_program: program2)
      StudentProgram.create!(user: student_user, program: program2)
    end

    context "when authenticated as student" do
      before { sign_in_as(student_user) }

      it "sets the selected department in session" do
        post select_department_student_dashboard_path, params: { department_id: department2.id }
        expect(session[:selected_department_id]).to eq(department2.id)
      end

      it "redirects to dashboard with notice" do
        post select_department_student_dashboard_path, params: { department_id: department2.id }
        expect(response).to redirect_to(student_dashboard_path)
        follow_redirect!
        expect(response.body).to include("Department selected")
      end

      it "rejects invalid department" do
        invalid_department = Department.create!(name: "Invalid Department")
        post select_department_student_dashboard_path, params: { department_id: invalid_department.id }
        expect(session[:selected_department_id]).not_to eq(invalid_department.id)
        follow_redirect!
        expect(response.body).to include("Invalid department")
      end

      it "only allows departments the student is enrolled in" do
        other_department = Department.create!(name: "Other Department")
        post select_department_student_dashboard_path, params: { department_id: other_department.id }
        expect(session[:selected_department_id]).not_to eq(other_department.id)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post select_department_student_dashboard_path, params: { department_id: department.id }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
