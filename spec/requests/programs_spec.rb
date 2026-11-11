require 'rails_helper'

RSpec.describe "Programs", type: :request do
  let(:department) { Department.create!(name: "Test Department") }
  let(:program) { Program.create!(name: "Test Program", department: department, default_appointment_length: 30, information_email_address: "test@example.com") }

  describe "GET /departments/:department_id/programs" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_programs_path(department)
        expect(response).to have_http_status(:success)
      end

      # LRA-1471: shared footer text must keep ≥4.5:1 contrast (gray-700 on white ≈10.3:1)
      it "renders the shared footer with sufficient text contrast classes" do
        get department_programs_path(department)

        footer_html = response.body[/<footer\b[\s\S]*?<\/footer>/]
        expect(footer_html).to be_present
        expect(footer_html).to include("Privacy Notice")
        expect(footer_html).to include("734.615.0100")
        expect(footer_html).to include("The Regents of the University of Michigan")
        expect(footer_html).to include("text-gray-700")
        expect(footer_html).not_to include("text-gray-400")
      end
    end

    context "when authenticated as department admin" do
      before { sign_in_as_department_admin(department) }

      it "returns http success" do
        get department_programs_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_programs_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get department_program_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get department_program_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/new" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get new_department_program_path(department)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_department_program_path(department)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /departments/:department_id/programs" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "creates a program" do
        expect {
          post department_programs_path(department), params: {
            program: { name: "New Program", default_appointment_length: 30, information_email_address: "new@example.com" }
          }
        }.to change { Program.count }.by(1)
        expect(response).to redirect_to(department_program_path(department, Program.last))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post department_programs_path(department), params: {
          program: { name: "New Program", default_appointment_length: 30 }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:id/edit" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "returns http success" do
        get edit_department_program_path(department, program)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get edit_department_program_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "updates the program" do
        patch department_program_path(department, program), params: {
          program: { name: "Updated Program" }
        }
        expect(response).to redirect_to(department_program_path(department, program))
        expect(program.reload.name).to eq("Updated Program")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        patch department_program_path(department, program), params: {
          program: { name: "Updated Program" }
        }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /departments/:department_id/programs/:id" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "deletes the program" do
        program_to_delete = Program.create!(name: "To Delete", department: department, default_appointment_length: 30, information_email_address: "test@example.com")
        expect {
          delete department_program_path(department, program_to_delete)
        }.to change { Program.count }.by(-1)
        expect(response).to redirect_to(department_programs_path(department))
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        delete department_program_path(department, program)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /departments/:department_id/programs/:id/edit_content" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "includes author-facing alt text controls" do
        get edit_content_department_program_path(department, program)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Image alternative text")
        expect(response.body).to include("Decorative image")
        expect(response.body).to include('data-controller="trix-alt-text"')
      end
    end
  end

  describe "PATCH /departments/:department_id/programs/:id/update_content" do
    context "when authenticated as super admin" do
      before { sign_in_as_super_admin }

      it "saves dashboard image alt text" do
        image = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: image,
            image_alt: "Department open house photo",
            image_decorative: "0"
          }
        }
        expect(response).to redirect_to(department_program_path(department, program))
        program.reload
        expect(program.image).to be_attached
        expect(program.image_alt).to eq("Department open house photo")
        expect(program.image_decorative).to be false
      end

      it "allows decorative dashboard images with empty alt" do
        image = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: image,
            image_alt: "",
            image_decorative: "1"
          }
        }
        expect(response).to redirect_to(department_program_path(department, program))
        program.reload
        expect(program.image_decorative).to be true
        expect(program.dashboard_image_alt).to eq("")
      end

      it "rejects a new informative image without alt text" do
        image = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: image,
            image_alt: "",
            image_decorative: "0"
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be provided, or mark the image as decorative")
        expect(response.body).to include("program[image_signed_id]")
        expect(program.reload.image).not_to be_attached
      end

      it "preserves a rejected upload via signed id when alt text is supplied on retry" do
        image = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: image,
            image_alt: "",
            image_decorative: "0"
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)

        signed_id = Nokogiri::HTML(response.body)
          .at_css('input[name="program[image_signed_id]"]')
          &.[]("value")
        expect(signed_id).to be_present

        patch update_content_department_program_path(department, program), params: {
          program: {
            image_signed_id: signed_id,
            image_alt: "Retained upload banner",
            image_decorative: "0"
          }
        }

        expect(response).to redirect_to(department_program_path(department, program))
        program.reload
        expect(program.image).to be_attached
        expect(program.image_alt).to eq("Retained upload banner")
      end

      it "re-renders safely when replacing a persisted image without alt text" do
        existing = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: existing,
            image_alt: "Existing banner",
            image_decorative: "0"
          }
        }
        expect(response).to redirect_to(department_program_path(department, program))
        expect(program.reload.image).to be_attached

        replacement = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: replacement,
            image_alt: "",
            image_decorative: "0"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be provided, or mark the image as decorative")
        expect(response.body).to include("program[image_signed_id]")
        expect(program.reload.image).to be_attached
        expect(program.image_alt).to eq("Existing banner")
      end

      it "rejects clearing alt text on an existing informative image" do
        image = fixture_file_upload(Rails.root.join("spec/fixtures/files/program_image.png"), "image/png")
        patch update_content_department_program_path(department, program), params: {
          program: {
            image: image,
            image_alt: "Existing banner",
            image_decorative: "0"
          }
        }
        expect(response).to redirect_to(department_program_path(department, program))

        patch update_content_department_program_path(department, program), params: {
          program: {
            image_alt: "",
            image_decorative: "0"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("must be provided, or mark the image as decorative")
        expect(program.reload.image_alt).to eq("Existing banner")
      end
    end
  end
end
