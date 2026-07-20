# frozen_string_literal: true

require "rails_helper"

# Prova de ponta a ponta da integração Registry -> Tenancy -> Registry:
# RegisterOccupant chama InviteMember diretamente (Open Host Service), e
# quando o convite é aceito, o evento publicado por Tenancy é escutado por
# Registry (config/initializers/domain_events.rb) e reconcilia Person.user_id
# pelo invitation_id — nunca por email. Ver design.md Decisão 6.
RSpec.describe "Registry <-> Tenancy reconciliation" do
  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  def valid_cpf(seed = 1)
    base = format("%09d", 700_000_000 + seed)
    digits = base.chars.map(&:to_i)
    d1_sum = digits.each_with_index.sum { |d, i| d * (10 - i) }
    d1 = (d1_sum % 11) < 2 ? 0 : 11 - (d1_sum % 11)
    d2_sum = (digits + [d1]).each_with_index.sum { |d, i| d * (11 - i) }
    d2 = (d2_sum % 11) < 2 ? 0 : 11 - (d2_sum % 11)
    "#{base}#{d1}#{d2}"
  end

  it "fills Person.user_id when the invitation created by RegisterOccupant is accepted" do
    register_result = Registry::RegisterOccupant.new.call(
      actor: admin_user,
      unit: unit,
      person_attributes: { name: "Dono", cpf: valid_cpf },
      owner: true,
      grant_access: true,
      email: "dono-e2e@example.com"
    )
    expect(register_result).to be_success

    person = register_result.value!.person
    expect(person.user_id).to be_nil
    expect(person.pending_invitation_id).to be_present

    invitation = Tenancy::Invitation.find(person.pending_invitation_id)

    accept_result = Tenancy::AcceptInvitation.new.call(token: invitation.token, password: "password123", name: "Dono")
    expect(accept_result).to be_success

    expect(person.reload.user_id).to eq(accept_result.value!.user_id)
    expect(person.pending_invitation_id).to be_nil
  end

  it "does not affect Registry when an unrelated (staff) invitation is accepted" do
    staff_invitation = Tenancy::InviteMember.new.call(condominium: condominium, email: "porteiro@example.com", role: "service_provider").value!

    expect do
      Tenancy::AcceptInvitation.new.call(token: staff_invitation.token, password: "password123", name: "Porteiro")
    end.not_to change(Registry::Person, :count)
  end
end
