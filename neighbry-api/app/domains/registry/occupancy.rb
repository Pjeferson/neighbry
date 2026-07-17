# frozen_string_literal: true

module Registry
  class Occupancy < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :unit
    belongs_to :person

    validates :start_date, presence: true
    validate :owner_and_responsible_not_both_true
    validate :person_belongs_to_same_condominium
    validate :only_one_active_owner_per_unit
    validate :only_one_active_responsible_per_unit
    validate :only_one_active_occupancy_per_person_and_unit

    before_validation :set_condominium_from_unit
    before_validation :set_start_date, on: :create

    def active?
      end_date.nil?
    end

    def end!(date: Date.current)
      update!(end_date: date)
    end

    private

    def set_condominium_from_unit
      self.condominium_id ||= unit&.condominium_id
    end

    def set_start_date
      self.start_date ||= Date.current
    end

    def owner_and_responsible_not_both_true
      return unless owner? && responsible?

      errors.add(:base, "owner and responsible cannot both be true on the same Occupancy")
    end

    def person_belongs_to_same_condominium
      return if person.nil? || unit.nil?
      return if person.condominium_id == unit.condominium_id

      errors.add(:person, "must belong to the same condominium as the unit")
    end

    def only_one_active_owner_per_unit
      return unless owner? && active? && unit_id.present?

      scope = Occupancy.where(unit_id: unit_id, owner: true, end_date: nil)
      scope = scope.where.not(id: id) if persisted?
      errors.add(:base, "unit already has an active owner") if scope.exists?
    end

    def only_one_active_responsible_per_unit
      return unless responsible? && active? && unit_id.present?

      scope = Occupancy.where(unit_id: unit_id, responsible: true, end_date: nil)
      scope = scope.where.not(id: id) if persisted?
      errors.add(:base, "unit already has an active responsible") if scope.exists?
    end

    def only_one_active_occupancy_per_person_and_unit
      return unless active? && unit_id.present? && person_id.present?

      scope = Occupancy.where(unit_id: unit_id, person_id: person_id, end_date: nil)
      scope = scope.where.not(id: id) if persisted?
      errors.add(:base, "person already has an active occupancy in this unit") if scope.exists?
    end
  end
end
