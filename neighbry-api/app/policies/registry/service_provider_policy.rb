# frozen_string_literal: true

module Registry
  # Autorização de RegisterServiceProvider — não é por Unit (prestador não
  # ocupa unidade), é por Condominium: admin, ou qualquer Person com
  # owner/responsible ativo em alguma Unit desse condomínio.
  class ServiceProviderPolicy
    attr_reader :user, :condominium

    def initialize(user, condominium)
      @user = user
      @condominium = condominium
    end

    def create?
      admin? || owner_or_responsible_somewhere?
    end

    private

    def admin?
      return false unless user

      Tenancy::Membership.active.admin.exists?(user_id: user.id, condominium_id: condominium.id)
    end

    def owner_or_responsible_somewhere?
      return false unless user

      Occupancy
        .where(condominium_id: condominium.id, end_date: nil)
        .where("owner = true OR responsible = true")
        .joins(:person)
        .exists?(people: { user_id: user.id })
    end
  end
end
