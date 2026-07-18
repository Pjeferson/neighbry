# frozen_string_literal: true

module Notice
  class CreateAviso
    include Dry::Monads[:result]

    def call(actor:, condominium:, titulo:, corpo:, tipo:, building_id: nil, unit_id: nil)
      return Failure(:unauthorized) unless AvisoPolicy.new(actor, condominium).create?

      aviso = Aviso.new(
        condominium: condominium,
        titulo: titulo,
        corpo: corpo,
        tipo: tipo,
        building_id: building_id,
        unit_id: unit_id,
        criado_por: actor
      )

      ActiveRecord::Base.transaction do
        aviso.save!

        user_ids = ResolveDestinatarios.new.call(
          tipo: aviso.tipo,
          condominium_id: condominium.id,
          building_id: aviso.building_id,
          unit_id: aviso.unit_id
        )

        user_ids.each { |user_id| aviso.leituras.create!(user_id: user_id) }
      end

      Success(aviso)
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end
  end
end
