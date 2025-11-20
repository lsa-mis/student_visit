require 'rails_helper'

RSpec.describe "DepartmentAdmins", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/department_admins/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/department_admins/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/department_admins/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end
