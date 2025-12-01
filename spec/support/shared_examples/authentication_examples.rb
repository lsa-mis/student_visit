# Shared examples for testing authentication requirements

RSpec.shared_examples "requires authentication" do |path_method, *args|
  context "when unauthenticated" do
    it "redirects to login" do
      get public_send(path_method, *args)
      expect(response).to redirect_to(new_session_path)
    end
  end
end

RSpec.shared_examples "requires super admin" do |path_method, *args|
  context "when authenticated as super admin" do
    before { sign_in_as_super_admin }

    it "returns http success" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:success)
    end
  end

  context "when authenticated as department admin" do
    let(:department) { Department.create!(name: "Test Department") }
    before { sign_in_as_department_admin(department) }

    it "redirects or denies access" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:redirect).or have_http_status(:forbidden)
    end
  end

  context "when authenticated as student" do
    before { sign_in_as_student }

    it "redirects or denies access" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:redirect).or have_http_status(:forbidden)
    end
  end

  include_examples "requires authentication", path_method, *args
end

RSpec.shared_examples "requires department admin or super admin" do |path_method, *args|
  context "when authenticated as super admin" do
    before { sign_in_as_super_admin }

    it "returns http success" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:success)
    end
  end

  context "when authenticated as department admin" do
    let(:department) { Department.create!(name: "Test Department") }
    before { sign_in_as_department_admin(department) }

    it "returns http success" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:success)
    end
  end

  context "when authenticated as student" do
    before { sign_in_as_student }

    it "redirects or denies access" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:redirect).or have_http_status(:forbidden)
    end
  end

  include_examples "requires authentication", path_method, *args
end

RSpec.shared_examples "requires student" do |path_method, *args|
  context "when authenticated as student" do
    before { sign_in_as_student }

    it "returns http success" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:success)
    end
  end

  context "when authenticated as super admin" do
    before { sign_in_as_super_admin }

    it "redirects or denies access" do
      get public_send(path_method, *args)
      expect(response).to have_http_status(:redirect).or have_http_status(:forbidden)
    end
  end

  include_examples "requires authentication", path_method, *args
end
