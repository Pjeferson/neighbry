# frozen_string_literal: true

module Api
  module V1
    class CondominiumsController < ApplicationController
      # Busca pública por slug — deliberadamente sem ResolvesTenant: existe
      # justamente para ser chamada de fora de qualquer subdomínio de tenant
      # (host genérico), pra descobrir se um condomínio existe antes de
      # navegar pro subdomínio dele. Ver design.md (frontend-auth-onboarding).
      def show
        condominium = Tenancy::Condominium.find_by(slug: params[:slug])

        if condominium
          render json: { exists: true, name: condominium.name }, status: :ok
        else
          render json: { exists: false }, status: :not_found
        end
      end

      def create
        result = Tenancy::OnboardCondominium.new.call(
          condominium_name: params[:condominium_name],
          condominium_slug: params[:condominium_slug],
          admin_email: params[:admin_email],
          admin_password: params[:admin_password],
          admin_name: params[:admin_name]
        )

        if result.success?
          membership = result.value!
          render json: {
            condominium: { id: membership.condominium.id, name: membership.condominium.name, slug: membership.condominium.slug },
            admin: { id: membership.user.id, email: membership.user.email }
          }, status: :created
        else
          render json: { errors: result.failure.full_messages }, status: :unprocessable_content
        end
      end
    end
  end
end
