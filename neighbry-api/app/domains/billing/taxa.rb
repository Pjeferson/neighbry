# frozen_string_literal: true

module Billing
  class Taxa < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"

    validates :valor, presence: true, numericality: { greater_than: 0 }
    validates :descricao, presence: true
    validates :data_inicio, presence: true
    validate :immutable_fields, on: :update

    def aplicavel?(competencia)
      return false unless ativo?
      return false if competencia < data_inicio
      return false if data_fim.present? && competencia > data_fim

      true
    end

    private

    def immutable_fields
      %i[valor data_inicio data_fim].each do |attribute|
        errors.add(attribute, "cannot be changed after creation") if attribute_changed?(attribute)
      end
    end
  end
end
