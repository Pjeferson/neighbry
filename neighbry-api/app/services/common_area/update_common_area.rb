# frozen_string_literal: true

module CommonArea
  class UpdateCommonArea
    include Dry::Monads[:result]

    def call(actor:, common_area:, attributes:)
      return Failure(:unauthorized) unless CommonAreaPolicy.new(actor, common_area.condominium).update?

      if common_area.update(attributes)
        Success(common_area)
      else
        Failure(common_area.errors)
      end
    end
  end
end
