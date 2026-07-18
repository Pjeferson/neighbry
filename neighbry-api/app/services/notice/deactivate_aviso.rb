# frozen_string_literal: true

module Notice
  class DeactivateAviso
    include Dry::Monads[:result]

    def call(actor:, aviso:)
      return Failure(:unauthorized) unless AvisoPolicy.new(actor, aviso.condominium).create?

      aviso.update!(ativo: false)
      Success(aviso)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end
  end
end
