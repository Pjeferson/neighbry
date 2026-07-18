# frozen_string_literal: true

module Billing
  class Fatura < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :unit, class_name: "Registry::Unit"
    belongs_to :ciclo_cobranca, class_name: "Billing::CicloCobranca"
    has_many :cobrancas, class_name: "Billing::Cobranca", inverse_of: :fatura, dependent: :destroy
    has_one :pagamento, class_name: "Billing::Pagamento", dependent: :destroy
    accepts_nested_attributes_for :cobrancas

    enum :status, { pendente: "pendente", pago: "pago" }, validate: true, default: "pendente"

    validates :data_vencimento, presence: true
    validates :unit_id, uniqueness: { scope: :ciclo_cobranca_id }
    validates :cobrancas, presence: true

    def total
      cobrancas.sum(:valor)
    end

    def atrasada?
      pendente? && data_vencimento < Date.current
    end
  end
end
