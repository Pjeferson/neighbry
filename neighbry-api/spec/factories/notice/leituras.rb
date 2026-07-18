# frozen_string_literal: true

FactoryBot.define do
  factory :leitura, class: "Notice::Leitura" do
    association :aviso
    association :user
  end
end
