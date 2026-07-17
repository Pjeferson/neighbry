# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        include ResolvesTenant
        skip_before_action :resolve_tenant!, only: [:destroy]

        respond_to :json

        # Sobrescrito por completo (não usa warden.authenticate!/super) para
        # garantir que o Membership seja checado ANTES de qualquer sign_in —
        # assim o JWT nunca é emitido para um par User+Condominium sem
        # Membership ativo. Ver design.md (add-tenancy) Decisão 3.
        def create
          self.resource = User.find_by(email: sign_in_params[:email])

          unless resource&.valid_password?(sign_in_params[:password])
            return render json: { error: "invalid_credentials" }, status: :unauthorized
          end

          membership = Tenancy::Membership.active.find_by(user: resource, condominium: Tenancy::Current.condominium)

          unless membership
            return render json: { error: "no_active_membership_for_tenant" }, status: :unauthorized
          end

          sign_in(resource_name, resource)
          respond_with resource
        end

        private

        def respond_with(resource, _opts = {})
          render json: {
            message: "Logged in successfully",
            user: { id: resource.id, email: resource.email, name: resource.name }
          }, status: :ok
        end

        # Gotcha devise-jwt: assinatura com (**) evita 401 em setup stateless
        def respond_to_on_destroy(**)
          render json: { message: "Logged out successfully" }, status: :ok
        end
      end
    end
  end
end
