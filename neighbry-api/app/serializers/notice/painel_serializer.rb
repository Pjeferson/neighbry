# frozen_string_literal: true

module Notice
  class PainelSerializer
    include JSONAPI::Serializer

    attributes :titulo, :corpo, :tipo

    attribute :total_destinatarios do |aviso|
      aviso.leituras.size
    end

    attribute :total_confirmados do |aviso|
      aviso.leituras.count(&:confirmado?)
    end

    attribute :confirmacoes do |aviso|
      aviso.leituras.select(&:confirmado?).map { |leitura| { user_id: leitura.user_id, confirmado_em: leitura.confirmado_em } }
    end
  end
end
