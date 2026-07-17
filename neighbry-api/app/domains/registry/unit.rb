# frozen_string_literal: true

module Registry
  class Unit < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :building

    validates :identification, presence: true
    validate :condominium_matches_building

    before_validation :set_condominium_from_building

    private

    def set_condominium_from_building
      self.condominium_id ||= building&.condominium_id
    end

    def condominium_matches_building
      return if building.nil? || condominium_id.nil?

      errors.add(:condominium_id, "must match the building's condominium") if condominium_id != building.condominium_id
    end
  end
end
