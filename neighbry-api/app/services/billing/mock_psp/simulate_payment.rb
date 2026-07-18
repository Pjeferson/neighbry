# frozen_string_literal: true

require "net/http"

module Billing
  module MockPsp
    # Dublê de um PSP externo (PIX/boleto real) — não é domínio, é
    # infraestrutura de simulação. Faz uma chamada HTTP real ao endpoint de
    # webhook (não uma chamada Ruby direta), pra ensinar/exercitar a
    # fronteira de rede que um PSP de verdade teria (ver design.md Decisão
    # "Pagamento via webhook mockado com round-trip HTTP real").
    class SimulatePayment
      include Dry::Monads[:result]

      def call(fatura:)
        transaction_id = "MOCK-#{Time.current.to_i}"
        payload = { fatura_id: fatura.id, transaction_id: transaction_id }

        response = Net::HTTP.post(
          webhook_uri,
          payload.to_json,
          { "Content-Type" => "application/json", "X-Webhook-Secret" => webhook_secret }
        )

        if response.is_a?(Net::HTTPSuccess)
          Success(transaction_id)
        else
          Failure(:webhook_call_failed)
        end
      end

      private

      def webhook_uri
        URI.join(ENV.fetch("APP_BASE_URL", "http://localhost:3001"), "/api/v1/billing/webhooks/payments")
      end

      def webhook_secret
        ENV.fetch("BILLING_WEBHOOK_SECRET", "dev-webhook-secret")
      end
    end
  end
end
