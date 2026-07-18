# frozen_string_literal: true

FactoryBot.define do
  factory :condominium_billing_setting, class: "Billing::CondominiumBillingSetting" do
    association :condominium
    dia_cobranca { 5 }
    dias_para_vencimento { 10 }
  end
end
