# frozen_string_literal: true

module Tenancy
  # Aceita um convite pendente: cria (ou reaproveita) o User a partir do email
  # do convite e ativa o Membership correspondente. `password`/`name` só são
  # usados quando não existe User com esse email ainda — a própria pessoa
  # convidada é quem chama isso, nunca quem enviou o convite.
  class AcceptInvitation
    include Dry::Monads[:result]

    def call(token:, password: nil, name: nil)
      invitation = Invitation.find_by(token: token)
      return Failure(:not_found) if invitation.nil?
      return Failure(:expired) if invitation.expired?
      return Failure(:already_accepted) if invitation.accepted?

      user = User.find_by(email: invitation.email)
      return Failure(:already_member) if user && Membership.exists?(user_id: user.id)

      ActiveRecord::Base.transaction do
        user ||= create_user!(invitation, password:, name:)

        membership = Membership.create!(
          user: user,
          condominium: invitation.condominium,
          role: invitation.role,
          status: "active"
        )

        invitation.update!(accepted_at: Time.current)

        # Publica sem saber (nem se importar) se alguém está ouvindo — nunca
        # chama código de outro bounded context diretamente. Ver design.md
        # (add-registry-context) Decisão 6.
        ActiveSupport::Notifications.instrument(
          "tenancy.invitation_accepted",
          invitation_id: invitation.id,
          user_id: user.id
        )

        return Success(membership)
      end
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end

    private

    def create_user!(invitation, password:, name:)
      User.create!(email: invitation.email, password: password, name: name)
    end
  end
end
