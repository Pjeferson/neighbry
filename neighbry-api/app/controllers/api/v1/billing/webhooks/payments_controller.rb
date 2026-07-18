# frozen_string_literal: true

module Api
  module V1
    module Billing
      module Webhooks
        # Endpoint que existiria em produção com um PSP real, sem mudança
        # nenhuma — a única coisa mockada é quem chama ele
        # (Billing::MockPsp::SimulatePayment). Autenticação por segredo
        # estático, não por sessão de usuário (ver design.md).
        class PaymentsController < ApplicationController
          before_action :authenticate_webhook!

          def create
            fatura = ::Billing::Fatura.find(params[:fatura_id])

            result = ::Billing::ConfirmPayment.new.call(
              fatura: fatura,
              metodo: "webhook",
              transaction_id: params[:transaction_id]
            )

            if result.success?
              render json: { status: "confirmed" }, status: :ok
            else
              render json: { error: error_payload(result.failure) }, status: :unprocessable_content
            end
          end

          private

          def authenticate_webhook!
            provided = request.headers["X-Webhook-Secret"].to_s
            expected = ENV.fetch("BILLING_WEBHOOK_SECRET", "dev-webhook-secret")

            head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(provided, expected)
          end

          def error_payload(failure)
            failure.respond_to?(:full_messages) ? failure.full_messages : failure
          end
        end
      end
    end
  end
end
