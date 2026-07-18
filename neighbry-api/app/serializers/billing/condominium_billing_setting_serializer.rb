# frozen_string_literal: true

module Billing
  class CondominiumBillingSettingSerializer
    include JSONAPI::Serializer

    attributes :dia_cobranca, :dias_para_vencimento
  end
end
