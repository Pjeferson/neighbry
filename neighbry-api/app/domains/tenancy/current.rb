# frozen_string_literal: true

module Tenancy
  # Tenant resolvido por request (via subdomínio) — ver ResolvesTenant.
  class Current < ActiveSupport::CurrentAttributes
    attribute :condominium
  end
end
