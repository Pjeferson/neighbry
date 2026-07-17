# frozen_string_literal: true

FactoryBot.define do
  factory :condominium, class: "Tenancy::Condominium" do
    name { Faker::Company.name }
    sequence(:slug) { |n| "condominio-#{n}" }
  end
end
