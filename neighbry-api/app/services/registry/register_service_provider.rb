# frozen_string_literal: true

module Registry
  # Cadastra um prestador de serviço (Person sem Unit/Occupancy) e,
  # opcionalmente, concede acesso — mesmo padrão de RegisterOccupant, sem o
  # conceito de Unit. Ver design.md (add-registry-context) Decisão 7.
  class RegisterServiceProvider
    include Dry::Monads[:result]

    def call(actor:, condominium:, person_attributes:, grant_access: false, email: nil)
      return Failure(:unauthorized) unless ServiceProviderPolicy.new(actor, condominium).create?
      return Failure(:email_required) if grant_access && email.blank?

      existing_person = Person.find_by(condominium_id: condominium.id, cpf: person_attributes[:cpf])
      return Failure(:person_type_mismatch) if existing_person && !existing_person.service_provider?

      invitation = nil

      if grant_access
        return Failure(:email_already_member) if email_already_member?(email)

        invite_result = Tenancy::InviteMember.new.call(condominium: condominium, email: email, role: "resident")
        return Failure(invite_result.failure) unless invite_result.success?

        invitation = invite_result.value!
      end

      person = existing_person || Person.new(person_attributes.merge(condominium_id: condominium.id, type: "service_provider"))
      person.pending_invitation_id = invitation.id if grant_access

      if person.save
        Success(person)
      else
        Failure(person.errors)
      end
    end

    private

    def email_already_member?(email)
      user = User.find_by(email: email)
      user.present? && Tenancy::Membership.active.exists?(user_id: user.id)
    end
  end
end
