# frozen_string_literal: true

module Registry
  # Autorização por Unit para RegisterOccupant/EndOccupancy — não decide
  # "pode cadastrar", decide "pode cadastrar/encerrar ESSE papel nessa Unit".
  # Ver design.md (add-registry-context) Decisões 3 e 5.
  class OccupancyPolicy
    attr_reader :user, :unit

    def initialize(user, unit)
      @user = user
      @unit = unit
    end

    def create_owner?
      admin?
    end

    def create_responsible?
      admin? || owner_of_unit?
    end

    def create_occupant?
      admin? || owner_of_unit? || responsible_of_unit?
    end

    def end_owner?
      admin?
    end

    def end_responsible?
      admin? || owner_of_unit?
    end

    def end_occupant?
      admin? || owner_of_unit? || responsible_of_unit?
    end

    private

    def admin?
      return false unless user

      Tenancy::Membership.active.admin.exists?(user_id: user.id, condominium_id: unit.condominium_id)
    end

    def owner_of_unit?
      return false unless user

      active_occupancy_flag?(:owner)
    end

    def responsible_of_unit?
      return false unless user

      active_occupancy_flag?(:responsible)
    end

    def active_occupancy_flag?(flag)
      Occupancy
        .where(unit_id: unit.id, end_date: nil, flag => true)
        .joins(:person)
        .exists?(people: { user_id: user.id })
    end
  end
end
