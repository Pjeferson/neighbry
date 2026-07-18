# frozen_string_literal: true

module CommonArea
  class RegisterCommonArea
    include Dry::Monads[:result]

    def call(actor:, condominium:, nome:, capacidade:, descricao: nil, horario_funcionamento: nil, regras_uso: nil)
      return Failure(:unauthorized) unless CommonAreaPolicy.new(actor, condominium).create?

      common_area = CommonArea.new(
        condominium: condominium,
        nome: nome,
        capacidade: capacidade,
        descricao: descricao,
        horario_funcionamento: horario_funcionamento,
        regras_uso: regras_uso
      )

      if common_area.save
        Success(common_area)
      else
        Failure(common_area.errors)
      end
    end
  end
end
