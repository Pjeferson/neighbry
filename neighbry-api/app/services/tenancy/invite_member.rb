# frozen_string_literal: true

module Tenancy
  # Cria um convite de acesso para um Condominium. Deliberadamente não aceita
  # senha — só a pessoa convidada define a própria senha, em AcceptInvitation.
  class InviteMember
    include Dry::Monads[:result]

    EXPIRATION_PERIOD = 7.days

    def call(condominium:, email:, role:)
      invitation = condominium.invitations.new(
        email: email,
        role: role,
        expires_at: EXPIRATION_PERIOD.from_now
      )

      if invitation.save
        Success(invitation)
      else
        Failure(invitation.errors)
      end
    end
  end
end
