# frozen_string_literal: true

# Resolve o Condominium (tenant) a partir do subdomínio da requisição antes de
# qualquer autenticação acontecer. Ver design.md (add-tenancy) Decisão 3.
module ResolvesTenant
  extend ActiveSupport::Concern

  included do
    before_action :resolve_tenant!
  end

  private

  def resolve_tenant!
    condominium = Tenancy::Condominium.find_by(slug: request.subdomain)

    if condominium.nil?
      render json: { error: "condominium_not_found" }, status: :not_found
      return
    end

    Tenancy::Current.condominium = condominium
  end
end
