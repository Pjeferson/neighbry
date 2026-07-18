# frozen_string_literal: true

module Billing
  class GenerateBillingCycle
    include Dry::Monads[:result]

    def call(condominium:)
      return Failure(:no_billing_setting) unless CondominiumBillingSetting.exists?(condominium_id: condominium.id)

      competencia = Date.current.beginning_of_month
      existing = CicloCobranca.find_by(condominium: condominium, competencia: competencia)
      return Success(existing) if existing

      ciclo = CicloCobranca.create!(condominium: condominium, competencia: competencia, status: "gerando")
      Success(ciclo)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      # Corrida entre execuções concorrentes — o índice único já garantiu que
      # só um CicloCobranca existe; buscamos o que venceu a corrida.
      existing = CicloCobranca.find_by(condominium: condominium, competencia: competencia)
      existing ? Success(existing) : Failure(:could_not_create_cycle)
    end
  end
end
