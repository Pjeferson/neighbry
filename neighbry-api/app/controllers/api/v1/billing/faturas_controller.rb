# frozen_string_literal: true

module Api
  module V1
    module Billing
      class FaturasController < ApplicationController
        include ResolvesTenant

        before_action :authenticate_user!

        def confirm_payment
          fatura = ::Billing::Fatura.find_by!(id: params[:id], condominium_id: Tenancy::Current.condominium.id)

          unless ::Billing::PagamentoPolicy.new(current_user, fatura.condominium).confirm?
            return render json: { error: [:unauthorized] }, status: :unprocessable_content
          end

          result = ::Billing::ConfirmPayment.new.call(fatura: fatura, metodo: "manual")

          if result.success?
            render json: ::Billing::FaturaSerializer.new(fatura.reload).serializable_hash
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
