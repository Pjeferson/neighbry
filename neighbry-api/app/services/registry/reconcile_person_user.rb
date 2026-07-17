# frozen_string_literal: true

module Registry
  # Reage ao evento tenancy.invitation_accepted — nunca é chamado
  # diretamente por Tenancy, só se inscreve no evento (ver
  # config/initializers/domain_events.rb). Idempotente: rodar duas vezes pro
  # mesmo invitation_id não tem efeito na segunda (pending_invitation_id já
  # foi limpo na primeira).
  class ReconcilePersonUser
    def call(invitation_id:, user_id:)
      person = Person.find_by(pending_invitation_id: invitation_id)
      return unless person

      person.update!(user_id: user_id, pending_invitation_id: nil)
    end
  end
end
