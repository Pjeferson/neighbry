# frozen_string_literal: true

module Tenancy
  class MembershipSerializer
    include JSONAPI::Serializer

    attributes :role, :status, :user_id

    belongs_to :condominium
  end
end
