# frozen_string_literal: true

module Billing
  class FaturaSerializer
    include JSONAPI::Serializer

    attributes :status, :data_vencimento, :unit_id

    has_many :cobrancas, serializer: :cobranca

    attribute :total do |fatura|
      fatura.total
    end

    attribute :atrasada do |fatura|
      fatura.atrasada?
    end
  end
end
