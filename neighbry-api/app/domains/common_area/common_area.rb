# frozen_string_literal: true

module CommonArea
  class CommonArea < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"

    validates :nome, presence: true
    validates :capacidade, presence: true, numericality: { only_integer: true, greater_than: 0 }
  end
end
