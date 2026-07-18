# frozen_string_literal: true

module Billing
  class Pagamento < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :fatura, class_name: "Billing::Fatura"

    enum :metodo, { manual: "manual", webhook: "webhook" }, validate: true

    validates :fatura_id, uniqueness: true
    validates :valor, presence: true
    validates :data, presence: true
    validate :valor_matches_fatura_total

    private

    def valor_matches_fatura_total
      return if fatura.blank? || valor.blank?

      errors.add(:valor, "must equal the Fatura total") if valor != fatura.total
    end
  end
end
