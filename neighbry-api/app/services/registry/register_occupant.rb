# frozen_string_literal: true

module Registry
  # Cadastra uma Person numa Unit (dono, responsável ou morador comum) e,
  # opcionalmente, concede acesso ao sistema reaproveitando o convite de
  # Tenancy. Ver design.md (add-registry-context) Decisões 4, 6, 8 e 9.
  class RegisterOccupant
    include Dry::Monads[:result]

    def call(actor:, unit:, person_attributes:, owner: false, responsible: false, grant_access: false, email: nil)
      return Failure(:unauthorized) unless authorized?(actor, unit, owner: owner, responsible: responsible)
      return Failure(:email_required) if grant_access && email.blank?

      existing_person = Person.find_by(condominium_id: unit.condominium_id, cpf: person_attributes[:cpf])
      return Failure(:person_type_mismatch) if existing_person && !existing_person.resident?

      invitation = nil

      if grant_access
        return Failure(:email_already_member) if email_already_member?(email)

        invite_result = Tenancy::InviteMember.new.call(condominium: unit.condominium, email: email, role: "resident")
        return Failure(invite_result.failure) unless invite_result.success?

        invitation = invite_result.value!
      end

      person = existing_person || Person.new(person_attributes.merge(condominium_id: unit.condominium_id, type: "resident"))

      ActiveRecord::Base.transaction do
        person.pending_invitation_id = invitation.id if grant_access
        person.save!

        occupancy = Occupancy.create!(unit: unit, person: person, owner: owner, responsible: responsible)

        return Success(occupancy)
      end
    rescue ActiveRecord::RecordInvalid => e
      Failure(e.record.errors)
    end

    private

    def authorized?(actor, unit, owner:, responsible:)
      policy = OccupancyPolicy.new(actor, unit)
      return policy.create_owner? if owner
      return policy.create_responsible? if responsible

      policy.create_occupant?
    end

    def email_already_member?(email)
      user = User.find_by(email: email)
      user.present? && Tenancy::Membership.active.exists?(user_id: user.id)
    end
  end
end
