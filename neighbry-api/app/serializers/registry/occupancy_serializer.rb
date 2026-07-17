# frozen_string_literal: true

module Registry
  class OccupancySerializer
    include JSONAPI::Serializer

    attributes :owner, :responsible, :start_date, :end_date, :unit_id, :person_id
  end
end
