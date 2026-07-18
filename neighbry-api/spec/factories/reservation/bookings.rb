# frozen_string_literal: true

FactoryBot.define do
  factory :booking, class: "Reservation::Booking" do
    transient do
      condominium { create(:condominium) }
    end

    common_area { create(:common_area, condominium: condominium) }

    occupancy do
      unit = create(:unit, building: create(:building, condominium: condominium))
      create(:occupancy, owner: true, unit: unit)
    end

    data { Date.current + 1.day }
    turno { "manha" }
  end
end
