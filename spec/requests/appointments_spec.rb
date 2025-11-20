require 'rails_helper'

RSpec.describe "Appointments", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/appointments/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/appointments/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /bulk_upload" do
    it "returns http success" do
      get "/appointments/bulk_upload"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /process_bulk_upload" do
    it "returns http success" do
      get "/appointments/process_bulk_upload"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /by_faculty" do
    it "returns http success" do
      get "/appointments/by_faculty"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /by_student" do
    it "returns http success" do
      get "/appointments/by_student"
      expect(response).to have_http_status(:success)
    end
  end
end
