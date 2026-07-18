# frozen_string_literal: true

module Billing
  class CondominiumBillingSettingPolicy
    include AdminCheckable

    attr_reader :user, :condominium

    def initialize(user, condominium)
      @user = user
      @condominium = condominium
    end

    def update?
      admin_of?(user, condominium.id)
    end
  end
end
