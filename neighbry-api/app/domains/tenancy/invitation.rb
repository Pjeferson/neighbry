# frozen_string_literal: true

module Tenancy
  class Invitation < ApplicationRecord
    belongs_to :condominium

    has_secure_token :token

    enum :role, { admin: "admin", manager: "manager", service_provider: "service_provider", resident: "resident" }, validate: true

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :expires_at, presence: true

    def expired?
      expires_at.past?
    end

    def accepted?
      accepted_at.present?
    end
  end
end
