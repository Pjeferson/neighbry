# frozen_string_literal: true

FactoryBot.define do
  factory :pagamento, class: "Billing::Pagamento" do
    association :fatura
    condominium { fatura.condominium }
    metodo { "manual" }
    valor { fatura.total }
    data { Time.current }
  end
end
