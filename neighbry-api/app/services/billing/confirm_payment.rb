# frozen_string_literal: true

module Billing
  # Autorização de QUEM pode chamar isso é responsabilidade do chamador
  # (PagamentoPolicy para confirmação manual, segredo estático para o
  # webhook) — este service só executa a quitação em si, de forma
  # idempotente, independente do caminho de origem.
  class ConfirmPayment
    include Dry::Monads[:result]

    def call(fatura:, metodo:, transaction_id: nil)
      return Failure(:already_paid) if fatura.pago?

      pagamento = Pagamento.new(
        condominium: fatura.condominium,
        fatura: fatura,
        metodo: metodo,
        valor: fatura.total,
        data: Time.current,
        transaction_id: transaction_id
      )

      ActiveRecord::Base.transaction do
        pagamento.save!
        fatura.update!(status: "pago")
      end

      ActiveSupport::Notifications.instrument("billing.fatura_paga", fatura_id: fatura.id)

      Success(pagamento)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    rescue ActiveRecord::RecordNotUnique
      # Segunda tentativa concorrente de pagar a mesma Fatura — o índice
      # único em fatura_id já impediu o segundo Pagamento.
      Failure(:already_paid)
    end
  end
end
