# frozen_string_literal: true

FactoryBot.define do
  factory :invitation, class: "Tenancy::Invitation" do
    association :condominium
    sequence(:email) { |n| "convidado#{n}@example.com" }
    role { "resident" }
    expires_at { 7.days.from_now }
  end
end
