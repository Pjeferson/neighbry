# frozen_string_literal: true

module Registry
  class RegisterBuilding
    include Dry::Monads[:result]

    def call(actor:, condominium:, name:)
      return Failure(:unauthorized) unless BuildingPolicy.new(actor, condominium).create?

      building = Building.new(condominium: condominium, name: name)

      if building.save
        Success(building)
      else
        Failure(building.errors)
      end
    end
  end
end
