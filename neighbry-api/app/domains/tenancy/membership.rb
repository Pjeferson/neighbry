# frozen_string_literal: true

module Tenancy
  class Membership < ApplicationRecord
    belongs_to :user
    belongs_to :condominium

    enum :role, { admin: "admin", manager: "manager", service_provider: "service_provider", resident: "resident" }, validate: true
    enum :status, { active: "active", revoked: "revoked" }, validate: true

    validates :user_id, uniqueness: true
  end
end
