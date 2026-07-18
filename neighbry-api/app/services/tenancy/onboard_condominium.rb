# frozen_string_literal: true

module Tenancy
  # Cria um Condominium novo e seu primeiro admin numa única operação —
  # fora da lógica de subdomínio (não existe tenant resolvido ainda).
  class OnboardCondominium
    include Dry::Monads[:result]

    def call(condominium_name:, condominium_slug:, admin_email:, admin_password:, admin_name:)
      ActiveRecord::Base.transaction do
        condominium = Condominium.create!(name: condominium_name, slug: condominium_slug)
        admin = User.create!(email: admin_email, password: admin_password, name: admin_name)
        membership = Membership.create!(user: admin, condominium: condominium, role: "admin", status: "active")

        ActiveSupport::Notifications.instrument("tenancy.condominium_onboarded", condominium_id: condominium.id)

        return Success(membership)
      end
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end
  end
end
