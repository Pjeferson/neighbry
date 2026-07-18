# frozen_string_literal: true

module Notice
  class LeituraSerializer
    include JSONAPI::Serializer

    attributes :aviso_id, :user_id, :confirmado_em
  end
end
