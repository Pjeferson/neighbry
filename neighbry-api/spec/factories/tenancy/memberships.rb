# frozen_string_literal: true

FactoryBot.define do
  factory :membership, class: "Tenancy::Membership" do
    association :user
    association :condominium
    role { "resident" }
    status { "active" }
  end
end
