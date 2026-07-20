# frozen_string_literal: true

module Notice
  # Calcula os user_id destinatários de um Aviso ainda não persistido — usado
  # só no momento da criação, pra tirar o snapshot em Notice::Leitura (ver
  # design.md Decisão "Destinatários calculados por dois caminhos
  # diferentes, conforme o tipo").
  class ResolveDestinatarios
    STAFF_ROLES = %w[admin manager service_provider].freeze

    def call(tipo:, condominium_id:, building_id: nil, unit_id: nil)
      case tipo.to_s
      when "todos" then user_ids_by_role(condominium_id, nil)
      when "moradores" then user_ids_by_role(condominium_id, "resident")
      when "staff" then user_ids_by_role(condominium_id, STAFF_ROLES)
      when "torre" then user_ids_by_units(Registry::Unit.where(building_id: building_id).select(:id))
      when "unidade" then user_ids_by_units([unit_id])
      else
        []
      end
    end

    private

    def user_ids_by_role(condominium_id, role)
      scope = Tenancy::Membership.active.where(condominium_id: condominium_id)
      scope = scope.where(role: role) if role
      scope.distinct.pluck(:user_id)
    end

    def user_ids_by_units(unit_ids)
      Registry::Occupancy
        .where(unit_id: unit_ids, end_date: nil)
        .joins(:person)
        .where.not(people: { user_id: nil })
        .distinct
        .pluck("people.user_id")
    end
  end
end
