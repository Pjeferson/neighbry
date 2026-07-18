# frozen_string_literal: true

module Notice
  class AvisoPolicy
    include AdminCheckable

    attr_reader :user, :condominium

    def initialize(user, condominium)
      @user = user
      @condominium = condominium
    end

    def create?
      admin_of?(user, condominium.id)
    end

    def view_painel?
      admin_of?(user, condominium.id)
    end
  end
end
