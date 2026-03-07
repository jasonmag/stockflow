Rails.application.routes.draw do
  namespace :admin do
    root "dashboard#index"
    resources :users, only: %i[index show edit update]
    resources :businesses, only: %i[index show]
    resources :memberships, only: %i[create update destroy]
    resource :impersonation, only: %i[create destroy]
  end

  resource :session, only: %i[create destroy]
  get "login", to: "sessions#new", as: :login
  get "admin/login", to: "sessions#admin_new", as: :admin_login
  get "about", to: "home#about", as: :about
  resources :passwords, param: :token
  resource :business, only: [] do
    patch :switch
  end

  root "home#index"

  resources :categories
  resources :customers
  resources :suppliers
  resources :products
  resources :locations
  resources :stock_movements, only: %i[index new create]
  resources :expenses
  resources :payables do
    member do
      patch :mark_paid
    end
  end
  resources :payments, only: %i[index]
  resources :purchases do
    member do
      patch :receive
    end
  end
  resources :receivables do
    member do
      patch :mark_collected
    end
  end
  resources :collections, only: %i[index]
  resources :deliveries do
    member do
      post :generate_pdf
      get :download_pdf
      post :email_pdf
      patch :mark_delivered
    end
  end
  resources :notifications, only: %i[index] do
    member do
      patch :mark_read
    end
  end
  get "user_guide", to: "user_guides#show"
  get "dashboard", to: "dashboard#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
