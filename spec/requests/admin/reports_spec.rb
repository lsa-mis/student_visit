require 'rails_helper'

RSpec.describe "Admin::Reports", type: :request do
  describe "GET /students" do
    it "returns http success" do
      get "/admin/reports/students"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /appointments" do
    it "returns http success" do
      get "/admin/reports/appointments"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /calendar" do
    it "returns http success" do
      get "/admin/reports/calendar"
      expect(response).to have_http_status(:success)
    end
  end
end
