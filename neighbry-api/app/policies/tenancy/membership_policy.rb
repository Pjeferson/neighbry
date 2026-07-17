# frozen_string_literal: true

module Tenancy
  # Restrito a admin no v1 — quem pode convidar (create) e revogar
  # (update/destroy) Memberships no Condominium atual (Tenancy::Current).
  class MembershipPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def create?
      admin?
    end

    def update?
      admin?
    end

    def destroy?
      admin?
    end

    def revoke?
      admin?
    end

    private

    def admin?
      return false unless user

      Membership.active.admin.exists?(user_id: user.id, condominium: Current.condominium)
    end
  end
end
