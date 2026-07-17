# frozen_string_literal: true

FactoryBot.define do
  factory :unit, class: "Registry::Unit" do
    association :building
    sequence(:identification) { |n| "Unidade #{n}" }
  end
end
