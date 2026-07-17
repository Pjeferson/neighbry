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
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
