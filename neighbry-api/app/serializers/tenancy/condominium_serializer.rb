# frozen_string_literal: true

module Tenancy
  class CondominiumSerializer
    include JSONAPI::Serializer

    attributes :name, :slug
  end
end
