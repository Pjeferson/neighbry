# frozen_string_literal: true

module Billing
  class CondominiumBillingSetting < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"

    validates :condominium_id, uniqueness: true
    validates :dia_cobranca, presence: true,
      numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 15 }
    validates :dias_para_vencimento, presence: true, numericality: { only_integer: true, greater_than: 0 }
  end
end
