# frozen_string_literal: true

module Api
  module V1
    class OccupanciesController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def create
        unit = Registry::Unit.find_by!(id: params[:unit_id], condominium_id: Tenancy::Current.condominium.id)

        result = Registry::RegisterOccupant.new.call(
          actor: current_user,
          unit: unit,
          person_attributes: { name: params[:name], cpf: params[:cpf] },
          owner: cast_bool(params[:owner]),
          responsible: cast_bool(params[:responsible]),
          grant_access: cast_bool(params[:grant_access]),
          email: params[:email]
        )

        if result.success?
          render json: Registry::OccupancySerializer.new(result.value!).serializable_hash, status: :created
        else
          render json: { error: error_payload(result.failure) }, status: :unprocessable_content
        end
      end

      def close
        occupancy = Registry::Occupancy.find_by!(id: params[:id], condominium_id: Tenancy::Current.condominium.id)

        result = Registry::EndOccupancy.new.call(actor: current_user, occupancy: occupancy)

        if result.success?
          render json: Registry::OccupancySerializer.new(result.value!).serializable_hash, status: :ok
        else
          render json: { error: error_payload(result.failure) }, status: :unprocessable_content
        end
      end

      private

      def cast_bool(value)
        ActiveModel::Type::Boolean.new.cast(value) || false
      end

      def error_payload(failure)
        failure.respond_to?(:full_messages) ? failure.full_messages : failure
      end
    end
  end
end
