Rails.application.routes.draw do
  namespace :admin do
    resources :departments, only: [] do
      resources :programs, only: [] do
        resources :reports, only: [] do
          collection do
            get :students
            get :appointments
            get :calendar
          end
        end
      end
    end
  end
  resource :session
  resources :passwords, param: :token
  root "home#index"
  get "home/index"

  namespace :student do
    resource :dashboard, only: [:show] do
      post :select_department, on: :collection
    end

    resources :departments, only: [] do
      resources :programs, only: [] do
        resources :questionnaires, only: [:index, :show, :edit, :update]
        resources :appointments, only: [:index] do
          collection do
            get :available
            get :my_appointments
          end
          member do
            post :select
            delete :delete
          end
        end
        resource :calendar, only: [:show], controller: :calendar
      end
      resource :map, only: [:show], controller: :map
    end
  end

  resources :departments do
    member do
      get :edit_content
      patch :update_content
    end
    resources :programs do
      resources :students, only: [:index, :edit, :update, :destroy] do
        collection do
          get :bulk_upload
          post :process_bulk_upload
        end
      end
      resources :questionnaires do
        resources :questions
      end
      resources :calendar_events
      resources :appointments, only: [:index, :show] do
        collection do
          get :bulk_upload
          post :process_bulk_upload
          get :by_faculty
          get :by_student
        end
      end
    end
    resources :vips do
      collection do
        get :bulk_upload
        post :process_bulk_upload
      end
    end
    resources :affiliated_resources
    resources :department_admins, only: [:index, :create, :destroy], as: :admins
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Mount the feedback gem engine
  mount LsaTdxFeedback::Engine => "/lsa_tdx_feedback", as: "lsa_tdx_feedback"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" unless Rails.env.production?
end
