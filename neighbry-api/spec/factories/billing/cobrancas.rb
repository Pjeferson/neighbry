# frozen_string_literal: true

FactoryBot.define do
  factory :cobranca, class: "Billing::Cobranca" do
    association :fatura
    condominium { fatura.condominium }
    taxa { association :taxa, condominium: condominium }
    valor { 100.0 }
  end
end
