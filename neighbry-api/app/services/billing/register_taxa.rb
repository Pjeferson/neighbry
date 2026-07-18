# frozen_string_literal: true

module Billing
  class RegisterTaxa
    include Dry::Monads[:result]

    def call(actor:, condominium:, valor:, descricao:, data_inicio:, data_fim: nil)
      return Failure(:unauthorized) unless TaxaPolicy.new(actor, condominium).create?

      taxa = Taxa.new(
        condominium: condominium,
        valor: valor,
        descricao: descricao,
        data_inicio: data_inicio,
        data_fim: data_fim
      )

      if taxa.save
        Success(taxa)
      else
        Failure(taxa.errors)
      end
    end
  end
end
