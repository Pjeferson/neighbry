# frozen_string_literal: true

FactoryBot.define do
  factory :taxa, class: "Billing::Taxa" do
    association :condominium
    valor { 100.0 }
    descricao { "Taxa condominial" }
    data_inicio { Date.current.beginning_of_month }
  end
end
