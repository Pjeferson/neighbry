# frozen_string_literal: true

module CommonArea
  class CommonAreaPolicy
    include AdminCheckable

    attr_reader :user, :condominium

    def initialize(user, condominium)
      @user = user
      @condominium = condominium
    end

    def create?
      admin_of?(user, condominium.id)
    end

    def update?
      admin_of?(user, condominium.id)
    end

    def list?
      return false unless user

      Tenancy::Membership.active.exists?(user_id: user.id, condominium_id: condominium.id)
    end
  end
end
