# frozen_string_literal: true

module Api
  module V1
    module Billing
      class MockPspController < ApplicationController
        include ResolvesTenant

        before_action :authenticate_user!

        def simulate
          fatura = ::Billing::Fatura.find_by!(id: params[:fatura_id], condominium_id: Tenancy::Current.condominium.id)

          unless ::Billing::PagamentoPolicy.new(current_user, fatura.condominium).confirm?
            return render json: { error: [:unauthorized] }, status: :unprocessable_content
          end

          result = ::Billing::MockPsp::SimulatePayment.new.call(fatura: fatura)

          if result.success?
            render json: { status: "simulated", transaction_id: result.value! }, status: :ok
          else
            render json: { error: result.failure }, status: :unprocessable_content
          end
        end
      end
    end
  end
end
