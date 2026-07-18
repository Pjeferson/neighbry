# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation::CreateBooking do
  subject(:service) { described_class.new }

  around do |example|
    travel_to(Date.new(2026, 7, 31)) { example.run }
  end

  let(:condominium) { create(:condominium) }
  let(:unit) { create(:unit, building: create(:building, condominium: condominium)) }
  let(:common_area) { create(:common_area, condominium: condominium) }

  def owner_user
    user = create(:user)
    person = create(:person, condominium: condominium, user: user)
    create(:occupancy, unit: unit, person: person, owner: true)
    user
  end

  it "creates a Booking for the owner's own unit" do
    result = service.call(actor: owner_user, unit: unit, common_area: common_area, data: Date.current + 1.day, turno: "manha")

    expect(result).to be_success
    expect(result.value!.unit_id).to eq(unit.id)
    expect(result.value!.common_area_id).to eq(common_area.id)
  end

  it "rejects a user with no active role in the unit" do
    plain_user = create(:user)
    create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")

    result = service.call(actor: plain_user, unit: unit, common_area: common_area, data: Date.current + 1.day, turno: "manha")

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end

  it "rejects a booking outside the 30-day window" do
    result = service.call(actor: owner_user, unit: unit, common_area: common_area, data: Date.current + 31.days, turno: "manha")

    expect(result).to be_failure
    expect(result.failure).to be_a(ActiveModel::Errors)
  end

  it "rejects a booking for an inactive CommonArea" do
    inactive = create(:common_area, condominium: condominium, ativo: false)

    result = service.call(actor: owner_user, unit: unit, common_area: inactive, data: Date.current + 1.day, turno: "manha")

    expect(result).to be_failure
    expect(result.failure).to be_a(ActiveModel::Errors)
  end

  it "rejects a second Booking for the same common_area, data and turno (race-safe)" do
    actor = owner_user
    service.call(actor: actor, unit: unit, common_area: common_area, data: Date.current + 1.day, turno: "manha")

    result = service.call(actor: actor, unit: unit, common_area: common_area, data: Date.current + 1.day, turno: "manha")

    expect(result).to be_failure
  end

  it "rejects a second Booking for the same unit and common_area within the same month" do
    actor = owner_user
    service.call(actor: actor, unit: unit, common_area: common_area, data: Date.current + 1.day, turno: "manha")

    result = service.call(actor: actor, unit: unit, common_area: common_area, data: Date.current + 2.days, turno: "tarde")

    expect(result).to be_failure
  end

  it "converts a database-level unique violation into a Failure" do
    booking = instance_double(Reservation::Booking, save: nil)
    allow(Reservation::Booking).to receive(:new).and_return(booking)
    allow(booking).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

    result = service.call(actor: owner_user, unit: unit, common_area: common_area, data: Date.current + 1.day, turno: "manha")

    expect(result).to be_failure
    expect(result.failure).to eq(:conflito_de_reserva)
  end
end
