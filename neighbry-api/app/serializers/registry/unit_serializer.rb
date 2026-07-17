# frozen_string_literal: true

module Registry
  class UnitSerializer
    include JSONAPI::Serializer

    attributes :identification
  end
end
