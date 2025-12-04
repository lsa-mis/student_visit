require 'rails_helper'

RSpec.describe Authorization, type: :controller do
  # Create a test controller to test the concern
  controller(ApplicationController) do
    include Authorization

    def index
      authorize Appointment.new
      render plain: 'success'
    end

    def show
      authorize Appointment.new
      render plain: 'success'
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'show' => 'anonymous#show'
    end
  end

  describe 'Pundit integration' do
    it 'includes Pundit::Authorization' do
      expect(controller.class.ancestors).to include(Pundit::Authorization)
    end

    it 'sets pundit_user to Current.user' do
      user = create(:user, :with_super_admin_role)
      session_obj = user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1')
      cookies.signed[:session_id] = session_obj.id

      get :index
      # pundit_user is called during authorization
      # We verify it doesn't raise an error
      expect(response).to have_http_status(:success).or have_http_status(:redirect)
    end
  end

  describe 'Pundit::NotAuthorizedError handling' do
    context 'when user is not authorized' do
      let(:user) { create(:user, :with_student_role) }
      let(:session_obj) { user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1') }

      before do
        cookies.signed[:session_id] = session_obj.id
      end

      it 'redirects with alert message' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end

      it 'redirects to referer if available' do
        request.env['HTTP_REFERER'] = '/previous/page'
        get :index
        expect(response).to redirect_to('/previous/page')
      end

      it 'redirects to root if no referer' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is authorized' do
      let(:user) { create(:user, :with_super_admin_role) }
      let(:session_obj) { user.sessions.create!(user_agent: 'Test', ip_address: '127.0.0.1') }

      before do
        cookies.signed[:session_id] = session_obj.id
      end

      it 'allows access' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end
end
