# frozen_string_literal: true

module Registry
  # Cadastro de Unit é admin-only, checado pelo condomínio do Building alvo.
  # Ver design.md Decisão 11.
  class UnitPolicy
    include AdminCheckable

    attr_reader :user, :building

    def initialize(user, building)
      @user = user
      @building = building
    end

    def create?
      admin_of?(user, building.condominium_id)
    end
  end
end
