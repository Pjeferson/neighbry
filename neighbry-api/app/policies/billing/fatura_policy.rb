# frozen_string_literal: true

module Billing
  class FaturaPolicy
    include AdminCheckable

    attr_reader :user, :unit

    def initialize(user, unit)
      @user = user
      @unit = unit
    end

    def view?
      admin_of?(user, unit.condominium_id) || occupant_of_unit?
    end

    private

    def occupant_of_unit?
      return false unless user

      Registry::Occupancy
        .where(unit_id: unit.id, end_date: nil)
        .joins(:person)
        .exists?(people: { user_id: user.id })
    end
  end
end
