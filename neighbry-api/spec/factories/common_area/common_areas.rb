# frozen_string_literal: true

FactoryBot.define do
  factory :common_area, class: "CommonArea::CommonArea" do
    association :condominium
    sequence(:nome) { |n| "Salão de Festas #{n}" }
    descricao { "Espaço para eventos" }
    capacidade { 50 }
    horario_funcionamento { "8h às 22h" }
    regras_uso { "Proibido som alto após 22h" }
  end
end
