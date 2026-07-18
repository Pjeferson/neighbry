# frozen_string_literal: true

module Billing
  class SetBillingDay
    include Dry::Monads[:result]

    def call(actor:, condominium:, dia_cobranca:, dias_para_vencimento:)
      return Failure(:unauthorized) unless CondominiumBillingSettingPolicy.new(actor, condominium).update?

      setting = CondominiumBillingSetting.find_or_initialize_by(condominium: condominium)
      setting.dia_cobranca = dia_cobranca
      setting.dias_para_vencimento = dias_para_vencimento

      if setting.save
        Success(setting)
      else
        Failure(setting.errors)
      end
    end
  end
end
