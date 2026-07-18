# frozen_string_literal: true

module Notice
  # Checagem de "é admin desse condomínio" — mesmo padrão de
  # Registry::AdminCheckable / Billing::AdminCheckable, replicado aqui
  # porque módulos não compartilham código entre bounded contexts.
  module AdminCheckable
    private

    def admin_of?(user, condominium_id)
      return false unless user

      Tenancy::Membership.active.admin.exists?(user_id: user.id, condominium_id: condominium_id)
    end
  end
end
