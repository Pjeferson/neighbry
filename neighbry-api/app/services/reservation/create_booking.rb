# frozen_string_literal: true

module Reservation
  class CreateBooking
    include Dry::Monads[:result]

    def call(actor:, unit:, common_area:, data:, turno:)
      return Failure(:unauthorized) unless BookingPolicy.new(actor, unit).create?

      occupancy = active_owner_or_responsible_occupancy(actor, unit)
      return Failure(:unauthorized) unless occupancy

      booking = Booking.new(
        common_area: common_area,
        occupancy: occupancy,
        data: data,
        turno: turno
      )

      if booking.save
        Success(booking)
      else
        Failure(booking.errors)
      end
    rescue ActiveRecord::RecordNotUnique
      Failure(:conflito_de_reserva)
    end

    private

    def active_owner_or_responsible_occupancy(actor, unit)
      base = Registry::Occupancy
        .where(unit_id: unit.id, end_date: nil)
        .joins(:person)
        .where(people: { user_id: actor.id })

      base.where(owner: true).or(base.where(responsible: true)).first
    end
  end
end
