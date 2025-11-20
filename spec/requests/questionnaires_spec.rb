require 'rails_helper'

RSpec.describe "Questionnaires", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/questionnaires/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/questionnaires/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/questionnaires/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/questionnaires/update"
      expect(response).to have_http_status(:success)
    end
  end
end
