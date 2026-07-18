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

        response = post_with_timeout(payload)

        if response.is_a?(Net::HTTPSuccess)
          Success(transaction_id)
        else
          Failure(:webhook_call_failed)
        end
      rescue Net::OpenTimeout, Net::ReadTimeout
        # Round-trip HTTP real (mesmo processo chamando a si mesmo) pode
        # ocasionalmente travar aguardando a resposta mesmo quando o
        # webhook já confirmou o pagamento no servidor (ver design.md
        # Risco "self-request timeout"). ConfirmPayment já é idempotente,
        # então uma nova tentativa do chamador é segura.
        Failure(:webhook_call_timed_out)
      end

      private

      def post_with_timeout(payload)
        uri = webhook_uri
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 5
        http.read_timeout = 5

        request = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json", "X-Webhook-Secret" => webhook_secret })
        request.body = payload.to_json

        http.request(request)
      end

      def webhook_uri
        # Chamada interna, container -> ele mesmo: usa a porta que o Puma
        # escuta dentro do container (3000), não a porta mapeada no host
        # (3001, documentada no CLAUDE.md) — ver config/puma.rb.
        URI.join(ENV.fetch("APP_BASE_URL", "http://localhost:3000"), "/api/v1/billing/webhooks/payments")
      end

      def webhook_secret
        ENV.fetch("BILLING_WEBHOOK_SECRET", "dev-webhook-secret")
      end
    end
  end
end
