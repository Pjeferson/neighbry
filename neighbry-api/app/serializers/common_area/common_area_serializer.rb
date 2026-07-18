# frozen_string_literal: true

module CommonArea
  class CommonAreaSerializer
    include JSONAPI::Serializer

    attributes :nome, :descricao, :capacidade, :horario_funcionamento, :regras_uso, :ativo
  end
end
