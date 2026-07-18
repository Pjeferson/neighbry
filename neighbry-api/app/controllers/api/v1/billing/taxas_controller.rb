# frozen_string_literal: true

module Api
  module V1
    module Billing
      class TaxasController < ApplicationController
        include ResolvesTenant

        before_action :authenticate_user!

        def create
          result = ::Billing::RegisterTaxa.new.call(
            actor: current_user,
            condominium: Tenancy::Current.condominium,
            valor: params[:valor],
            descricao: params[:descricao],
            data_inicio: params[:data_inicio],
            data_fim: params[:data_fim]
          )

          if result.success?
            render json: ::Billing::TaxaSerializer.new(result.value!).serializable_hash, status: :created
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
end
