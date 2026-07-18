# frozen_string_literal: true

module Billing
  class CobrancaSerializer
    include JSONAPI::Serializer

    attributes :taxa_id, :valor
  end
end
