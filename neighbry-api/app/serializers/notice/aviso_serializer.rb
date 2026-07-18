# frozen_string_literal: true

module Notice
  class AvisoSerializer
    include JSONAPI::Serializer

    attributes :titulo, :corpo, :tipo, :building_id, :unit_id, :ativo

    # Preenchido só quando params[:current_user_id] é passado (listagem
    # "meus avisos") — nil nas outras respostas (create/deactivate).
    attribute :confirmado_em do |aviso, params|
      next nil unless params[:current_user_id]

      aviso.leituras.detect { |leitura| leitura.user_id == params[:current_user_id] }&.confirmado_em
    end
  end
end
