# frozen_string_literal: true

module Reservation
  class BookingSerializer
    include JSONAPI::Serializer

    attributes :common_area_id, :unit_id, :occupancy_id, :data, :competencia, :turno, :cancelada_em
  end
end
