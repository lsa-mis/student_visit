require 'rails_helper'

RSpec.describe CsvResponder, type: :controller do
  # Create a test controller to test the concern
  controller(ApplicationController) do
    include CsvResponder

    def index
      csv_data = "Name,Email\nJohn,john@example.com"
      respond_with_csv(csv_data, 'test.csv')
    end
  end

  let(:user) { User.create!(email_address: 'test@example.com', password: 'password123') }
  let(:session) { user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1') }

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
    end
    cookies.signed[:session_id] = session.id
  end

  describe '#respond_with_csv' do
    it 'sends CSV data with correct headers' do
      get :index, format: :csv

      expect(response).to have_http_status(:success)
      expect(response.headers['Content-Type']).to include('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('filename="test.csv"')
    end

    it 'returns CSV content in response body' do
      get :index, format: :csv

      expect(response.body).to eq("Name,Email\nJohn,john@example.com")
    end

    it 'handles different filenames' do
      controller.define_singleton_method(:index) do
        csv_data = "Data\nValue"
        respond_with_csv(csv_data, 'custom-report.csv')
      end

      get :index, format: :csv

      expect(response.headers['Content-Disposition']).to include('filename="custom-report.csv"')
    end

    it 'only responds to CSV format' do
      # When HTML format is requested but not defined, Rails raises ActionController::UnknownFormat
      # This is the expected behavior - the concern only handles CSV format
      expect {
        get :index, format: :html
      }.to raise_error(ActionController::UnknownFormat)
    end
  end
end
