# frozen_string_literal: true

FactoryBot.define do
  factory :building, class: "Registry::Building" do
    association :condominium
    sequence(:name) { |n| "Bloco #{n}" }
  end
end
