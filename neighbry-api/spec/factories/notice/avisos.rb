# frozen_string_literal: true

FactoryBot.define do
  factory :aviso, class: "Notice::Aviso" do
    association :condominium
    titulo { "Aviso importante" }
    corpo { "Corpo do aviso" }
    tipo { "todos" }
    association :criado_por, factory: :user
  end
end
