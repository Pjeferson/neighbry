# frozen_string_literal: true

module Reservation
  class CancelBooking
    include Dry::Monads[:result]

    def call(actor:, booking:)
      return Failure(:unauthorized) unless BookingPolicy.new(actor, booking).cancel?
      return Failure(:already_cancelled) unless booking.active?

      booking.cancel!
      Success(booking)
    end
  end
end
