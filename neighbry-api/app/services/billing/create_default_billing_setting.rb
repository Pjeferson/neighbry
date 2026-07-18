# frozen_string_literal: true

module Billing
  # Reage ao evento tenancy.condominium_onboarded — nunca é chamado
  # diretamente por Tenancy, só se inscreve no evento (ver
  # config/initializers/domain_events.rb). Idempotente via
  # find_or_create_by!: rodar duas vezes pro mesmo condominium_id não cria
  # uma segunda configuração.
  class CreateDefaultBillingSetting
    DEFAULT_DIA_COBRANCA = 5
    DEFAULT_DIAS_PARA_VENCIMENTO = 10

    def call(condominium_id:)
      CondominiumBillingSetting.find_or_create_by!(condominium_id: condominium_id) do |setting|
        setting.dia_cobranca = DEFAULT_DIA_COBRANCA
        setting.dias_para_vencimento = DEFAULT_DIAS_PARA_VENCIMENTO
      end
    end
  end
end
