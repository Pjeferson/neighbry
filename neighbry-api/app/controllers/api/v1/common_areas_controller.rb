# frozen_string_literal: true

module Api
  module V1
    class CommonAreasController < ApplicationController
      include ResolvesTenant

      before_action :authenticate_user!

      def create
        result = ::CommonArea::RegisterCommonArea.new.call(
          actor: current_user,
          condominium: Tenancy::Current.condominium,
          nome: params[:nome],
          descricao: params[:descricao],
          capacidade: params[:capacidade],
          horario_funcionamento: params[:horario_funcionamento],
          regras_uso: params[:regras_uso]
        )

        if result.success?
          render json: ::CommonArea::CommonAreaSerializer.new(result.value!).serializable_hash, status: :created
        else
          render json: { error: error_payload(result.failure) }, status: :unprocessable_content
        end
      end

      def update
        common_area = ::CommonArea::CommonArea.find_by!(id: params[:id], condominium_id: Tenancy::Current.condominium.id)

        result = ::CommonArea::UpdateCommonArea.new.call(
          actor: current_user,
          common_area: common_area,
          attributes: params.permit(:nome, :descricao, :capacidade, :horario_funcionamento, :regras_uso, :ativo).to_h
        )

        if result.success?
          render json: ::CommonArea::CommonAreaSerializer.new(result.value!).serializable_hash
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
