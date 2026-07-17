# frozen_string_literal: true

module Api
  module V1
    class CondominiumsController < ApplicationController
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
