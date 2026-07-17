# frozen_string_literal: true

module Registry
  class RegisterUnit
    include Dry::Monads[:result]

    def call(actor:, building:, identification:)
      return Failure(:unauthorized) unless UnitPolicy.new(actor, building).create?

      unit = Unit.new(building: building, identification: identification)

      if unit.save
        Success(unit)
      else
        Failure(unit.errors)
      end
    end
  end
end
