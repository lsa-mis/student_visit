require 'rails_helper'

RSpec.describe "AffiliatedResources", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/affiliated_resources/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/affiliated_resources/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/affiliated_resources/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/affiliated_resources/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/affiliated_resources/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/affiliated_resources/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end
