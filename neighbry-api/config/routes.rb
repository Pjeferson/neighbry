# frozen_string_literal: true

Rails.application.routes.draw do
  # devise_for fora de qualquer namespace — requisito do devise-jwt
  devise_for :users,
    path: "api/v1/auth",
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      registration: "sign_up"
    },
    controllers: {
      sessions:      "api/v1/auth/sessions",
      registrations: "api/v1/auth/registrations"
    }

  namespace :api do
    namespace :v1 do
      resources :condominiums, only: [:create]

      resources :invitations, only: [:create] do
        post :accept, on: :collection
      end

      resources :memberships, only: [] do
        patch :revoke, on: :member
      end

      resources :buildings, only: [:create] do
        resources :units, only: [:create]
      end

      resources :units, only: [] do
        resources :occupancies, only: [:create]
      end

      resources :occupancies, only: [] do
        patch :close, on: :member
      end

      resources :service_providers, only: [:create]

      namespace :billing do
        resources :taxas, only: [:create]
        resource :settings, only: [:update]
        resources :faturas, only: [] do
          patch :confirm_payment, on: :member
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
