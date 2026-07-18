# frozen_string_literal: true

module Api
  module V1
    module Notice
      class AvisosController < ApplicationController
        include ResolvesTenant

        before_action :authenticate_user!

        def index
          avisos = ::Notice::Aviso
            .joins(:leituras)
            .where(leituras: { user_id: current_user.id }, ativo: true, condominium_id: Tenancy::Current.condominium.id)
            .includes(:leituras)

          render json: ::Notice::AvisoSerializer.new(avisos, params: { current_user_id: current_user.id }).serializable_hash
        end

        def create
          result = ::Notice::CreateAviso.new.call(
            actor: current_user,
            condominium: Tenancy::Current.condominium,
            titulo: params[:titulo],
            corpo: params[:corpo],
            tipo: params[:tipo],
            building_id: params[:building_id],
            unit_id: params[:unit_id]
          )

          if result.success?
            render json: ::Notice::AvisoSerializer.new(result.value!).serializable_hash, status: :created
          else
            render json: { error: error_payload(result.failure) }, status: :unprocessable_content
          end
        end

        def deactivate
          aviso = ::Notice::Aviso.find_by!(id: params[:id], condominium_id: Tenancy::Current.condominium.id)

          result = ::Notice::DeactivateAviso.new.call(actor: current_user, aviso: aviso)

          if result.success?
            render json: ::Notice::AvisoSerializer.new(result.value!).serializable_hash
          else
            render json: { error: error_payload(result.failure) }, status: :unprocessable_content
          end
        end

        def confirmar
          aviso = ::Notice::Aviso.find_by!(id: params[:id], condominium_id: Tenancy::Current.condominium.id)

          result = ::Notice::ConfirmLeitura.new.call(actor: current_user, aviso: aviso)

          if result.success?
            render json: ::Notice::LeituraSerializer.new(result.value!).serializable_hash
          else
            render json: { error: result.failure }, status: :unprocessable_content
          end
        end

        private

        def error_payload(failure)
          failure.respond_to?(:full_messages) ? failure.full_messages : failure
        end
      end
    end
  end
end
