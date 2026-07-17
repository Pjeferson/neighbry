# frozen_string_literal: true

module Registry
  class BuildingSerializer
    include JSONAPI::Serializer

    attributes :name
  end
end
