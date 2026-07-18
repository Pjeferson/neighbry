# frozen_string_literal: true

module Billing
  class CicloCobranca < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    has_many :faturas, class_name: "Billing::Fatura", dependent: :restrict_with_error

    enum :status, { gerando: "gerando", concluido: "concluido" }, validate: true, default: "gerando"

    validates :competencia, presence: true
    validates :condominium_id, uniqueness: { scope: :competencia }

    before_validation :truncate_competencia_to_month_start

    def concluir!
      update!(status: "concluido")
    end

    private

    def truncate_competencia_to_month_start
      self.competencia = competencia.beginning_of_month if competencia.present?
    end
  end
end
