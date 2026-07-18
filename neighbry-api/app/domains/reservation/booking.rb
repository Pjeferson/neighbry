# frozen_string_literal: true

module Reservation
  class Booking < ApplicationRecord
    MAX_DAYS_AHEAD = 30

    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :common_area, class_name: "CommonArea::CommonArea"
    belongs_to :occupancy, class_name: "Registry::Occupancy"
    belongs_to :unit, class_name: "Registry::Unit"

    enum :turno, { manha: "manha", tarde: "tarde", noite: "noite" }, validate: true

    validates :data, presence: true
    validate :data_within_window
    validate :occupancy_is_owner_or_responsible
    validate :common_area_is_ativo
    validate :unit_has_no_active_booking_for_common_area_in_competencia

    before_validation :set_unit_from_occupancy
    before_validation :truncate_competencia_to_month_start

    def active?
      cancelada_em.nil?
    end

    def cancel!
      update!(cancelada_em: Time.current)
    end

    private

    def set_unit_from_occupancy
      self.unit_id ||= occupancy&.unit_id
    end

    def truncate_competencia_to_month_start
      self.competencia = data.beginning_of_month if data.present?
    end

    def data_within_window
      return if data.blank?

      errors.add(:data, "não pode ser no passado") if data < Date.current
      errors.add(:data, "não pode ser mais de #{MAX_DAYS_AHEAD} dias no futuro") if data > Date.current + MAX_DAYS_AHEAD.days
    end

    def occupancy_is_owner_or_responsible
      return if occupancy.nil?

      return if occupancy.end_date.nil? && (occupancy.owner? || occupancy.responsible?)

      errors.add(:occupancy, "deve ser de um dono ou responsável ativo da unidade")
    end

    def common_area_is_ativo
      return if common_area.nil?

      errors.add(:common_area, "está inativo") unless common_area.ativo?
    end

    def unit_has_no_active_booking_for_common_area_in_competencia
      return if unit_id.blank? || common_area_id.blank? || competencia.blank?

      scope = Booking.where(unit_id: unit_id, common_area_id: common_area_id, competencia: competencia, cancelada_em: nil)
      scope = scope.where.not(id: id) if persisted?
      errors.add(:base, "unidade já tem uma reserva ativa para este espaço neste mês") if scope.exists?
    end
  end
end
