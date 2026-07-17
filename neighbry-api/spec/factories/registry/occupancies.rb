# frozen_string_literal: true

FactoryBot.define do
  factory :occupancy, class: "Registry::Occupancy" do
    unit
    person { association :person, condominium: unit.condominium }
    owner { false }
    responsible { false }
    start_date { Date.current }
  end
end
