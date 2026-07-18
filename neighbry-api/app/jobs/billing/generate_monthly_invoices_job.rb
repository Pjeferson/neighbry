# frozen_string_literal: true

module Billing
  # Roda diariamente (agendamento externo ao job em si — ex: sidekiq-cron ou
  # scheduler da plataforma, ainda não configurado nesta change). Idempotente
  # e retomável: pode rodar mais de uma vez no mesmo dia, ou pular dias, sem
  # duplicar CicloCobranca nem Fatura (ver design.md).
  class GenerateMonthlyInvoicesJob < ApplicationJob
    queue_as :default

    def perform
      hoje = Date.current

      CondominiumBillingSetting.where("dia_cobranca <= ?", hoje.day).find_each do |setting|
        condominium = Tenancy::Condominium.find(setting.condominium_id)

        ciclo_result = GenerateBillingCycle.new.call(condominium: condominium)
        next if ciclo_result.failure?

        ciclo = ciclo_result.value!
        next if ciclo.concluido?

        GenerateInvoicesForCycle.new.call(ciclo_cobranca: ciclo)
      end
    end
  end
end
