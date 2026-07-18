# frozen_string_literal: true

module Reservation
  # `resource` varia por ação: `create?` espera uma `Registry::Unit`,
  # `list?` espera um `Tenancy::Condominium`, `cancel?` espera a própria
  # `Booking` (ver design.md — nenhuma ação nesta v1 é admin-only).
  class BookingPolicy
    attr_reader :user, :resource

    def initialize(user, resource)
      @user = user
      @resource = resource
    end

    def create?
      return false unless user

      active_occupancies_for_user(resource.id)
        .where(owner: true)
        .or(active_occupancies_for_user(resource.id).where(responsible: true))
        .exists?
    end

    def list?
      return false unless user

      Tenancy::Membership.active.exists?(user_id: user.id, condominium_id: resource.id)
    end

    def cancel?
      return false unless user

      resource.occupancy.person.user_id == user.id
    end

    private

    def active_occupancies_for_user(unit_id)
      Registry::Occupancy
        .where(unit_id: unit_id, end_date: nil)
        .joins(:person)
        .where(people: { user_id: user.id })
    end
  end
end
