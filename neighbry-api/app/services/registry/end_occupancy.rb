# frozen_string_literal: true

module Registry
  # Encerra uma Occupancy existente — quem pode depende do papel sendo
  # encerrado (owner: só admin; responsible: admin ou owner; morador comum:
  # admin, owner ou responsible). Ver design.md Decisão 5 e OccupancyPolicy.
  class EndOccupancy
    include Dry::Monads[:result]

    def call(actor:, occupancy:)
      return Failure(:unauthorized) unless authorized?(actor, occupancy)

      occupancy.end!
      Success(occupancy)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end

    private

    def authorized?(actor, occupancy)
      policy = OccupancyPolicy.new(actor, occupancy.unit)
      return policy.end_owner? if occupancy.owner?
      return policy.end_responsible? if occupancy.responsible?

      policy.end_occupant?
    end
  end
end
