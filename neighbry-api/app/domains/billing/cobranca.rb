# frozen_string_literal: true

module Billing
  class Cobranca < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :fatura, class_name: "Billing::Fatura", inverse_of: :cobrancas
    belongs_to :taxa, class_name: "Billing::Taxa"

    validates :valor, presence: true, numericality: { greater_than: 0 }
  end
end
