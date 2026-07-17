# frozen_string_literal: true

module Tenancy
  # Cria um convite de acesso para um Condominium. Deliberadamente não aceita
  # senha — só a pessoa convidada define a própria senha, em AcceptInvitation.
  class InviteMember
    include Dry::Monads[:result]

    EXPIRATION_PERIOD = 7.days

    def call(condominium:, email:, role:)
      invalidate_pending_invitation(condominium, email)

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

    private

    # Convidar de novo substitui qualquer convite pendente anterior do mesmo
    # email — nunca dois pendentes simultâneos. Reaproveita o próprio
    # mecanismo de expiração (não precisa de coluna/estado novo). Ver
    # design.md (add-registry-context) Decisão 9.
    def invalidate_pending_invitation(condominium, email)
      Invitation
        .where(condominium: condominium, email: email, accepted_at: nil)
        .where("expires_at > ?", Time.current)
        .update_all(expires_at: 1.second.ago)
    end
  end
end
