# frozen_string_literal: true

FactoryBot.define do
  factory :ciclo_cobranca, class: "Billing::CicloCobranca" do
    association :condominium
    competencia { Date.current.beginning_of_month }
  end
end
