# frozen_string_literal: true

module Registry
  # Checagem de "é admin desse condomínio" compartilhada entre as policies de
  # Registry — extraída depois da terceira repetição (ver design.md Decisão 11).
  module AdminCheckable
    private

    def admin_of?(user, condominium_id)
      return false unless user

      Tenancy::Membership.active.admin.exists?(user_id: user.id, condominium_id: condominium_id)
    end
  end
end
