# frozen_string_literal: true

module Api
  module V1
    class BuildingsController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def create
        result = Registry::RegisterBuilding.new.call(
          actor: current_user,
          condominium: Tenancy::Current.condominium,
          name: params[:name]
        )

        if result.success?
          render json: Registry::BuildingSerializer.new(result.value!).serializable_hash, status: :created
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
