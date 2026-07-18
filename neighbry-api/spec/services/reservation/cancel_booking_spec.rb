# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation::CancelBooking do
  subject(:service) { described_class.new }

  around do |example|
    travel_to(Date.new(2026, 7, 31)) { example.run }
  end

  let(:booking) { create(:booking, data: Date.current + 1.day) }

  it "cancels the Booking when the actor is its author" do
    author = create(:user)
    booking.occupancy.person.update!(user: author)

    result = service.call(actor: author, booking: booking)

    expect(result).to be_success
    expect(booking.reload).not_to be_active
  end

  it "forbids a different resident from cancelling" do
    other_user = create(:user)

    result = service.call(actor: other_user, booking: booking)

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
    expect(booking.reload).to be_active
  end

  it "frees up the slot for a new Booking once cancelled" do
    author = create(:user)
    booking.occupancy.person.update!(user: author)

    service.call(actor: author, booking: booking)

    new_booking = build(:booking, common_area: booking.common_area,
      occupancy: create(:occupancy, unit: booking.unit, responsible: true),
      data: booking.data, turno: booking.turno)

    expect(new_booking).to be_valid
  end
end
