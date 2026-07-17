# frozen_string_literal: true

module Registry
  # Cadastro de Building é admin-only — estrutura física é administrativa,
  # diferente de cadastrar pessoas numa unidade já existente. Ver design.md
  # Decisão 11.
  class BuildingPolicy
    include AdminCheckable

    attr_reader :user, :condominium

    def initialize(user, condominium)
      @user = user
      @condominium = condominium
    end

    def create?
      admin_of?(user, condominium.id)
    end
  end
end
