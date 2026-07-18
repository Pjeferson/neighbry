# frozen_string_literal: true

module Billing
  class TaxaSerializer
    include JSONAPI::Serializer

    attributes :valor, :descricao, :data_inicio, :data_fim, :ativo
  end
end
