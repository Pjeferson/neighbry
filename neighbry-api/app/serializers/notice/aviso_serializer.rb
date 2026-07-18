# frozen_string_literal: true

module Notice
  class AvisoSerializer
    include JSONAPI::Serializer

    attributes :titulo, :corpo, :tipo, :building_id, :unit_id, :ativo
  end
end
