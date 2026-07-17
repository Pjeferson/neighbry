# frozen_string_literal: true

module Registry
  class PersonSerializer
    include JSONAPI::Serializer

    attributes :name, :cpf, :type, :user_id
  end
end
