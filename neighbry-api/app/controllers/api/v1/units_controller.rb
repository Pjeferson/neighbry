# frozen_string_literal: true

module Api
  module V1
    class UnitsController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def create
        building = Registry::Building.find_by!(id: params[:building_id], condominium_id: Tenancy::Current.condominium.id)

        result = Registry::RegisterUnit.new.call(
          actor: current_user,
          building: building,
          identification: params[:identification]
        )

        if result.success?
          render json: Registry::UnitSerializer.new(result.value!).serializable_hash, status: :created
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
