# frozen_string_literal: true

module Api
  module V1
    class ServiceProvidersController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def create
        result = Registry::RegisterServiceProvider.new.call(
          actor: current_user,
          condominium: Tenancy::Current.condominium,
          person_attributes: { name: params[:name], cpf: params[:cpf] },
          grant_access: ActiveModel::Type::Boolean.new.cast(params[:grant_access]),
          email: params[:email]
        )

        if result.success?
          render json: Registry::PersonSerializer.new(result.value!).serializable_hash, status: :created
        else
          render json: { error: error_payload(result.failure) }, status: :unprocessable_content
        end
      end

      private

      def error_payload(failure)
        failure.respond_to?(:full_messages) ? failure.full_messages : failure
      end
    end
  end
end
