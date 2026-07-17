# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::RegisterOccupant do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }

  def person_attrs(cpf: valid_cpf)
    { name: "Fulano", cpf: cpf }
  end

  # Offset alto pra nunca colidir com a sequence própria da factory :person
  # (que também gera CPF válido pelo mesmo algoritmo, a partir de 1).
  def valid_cpf(seed = 1)
    base = format("%09d", 500_000_000 + seed)
    digits = base.chars.map(&:to_i)
    d1_sum = digits.each_with_index.sum { |d, i| d * (10 - i) }
    d1 = (d1_sum % 11) < 2 ? 0 : 11 - (d1_sum % 11)
    d2_sum = (digits + [d1]).each_with_index.sum { |d, i| d * (11 - i) }
    d2 = (d2_sum % 11) < 2 ? 0 : 11 - (d2_sum % 11)
    "#{base}#{d1}#{d2}"
  end

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  def owner_user_for(target_unit)
    user = create(:user)
    person = create(:person, condominium: target_unit.condominium, user: user)
    create(:occupancy, unit: target_unit, person: person, owner: true)
    user
  end

  def responsible_user_for(target_unit)
    user = create(:user)
    person = create(:person, condominium: target_unit.condominium, user: user)
    create(:occupancy, unit: target_unit, person: person, responsible: true)
    user
  end

  it "admin registers the owner of a Unit" do
    result = service.call(actor: admin_user, unit: unit, person_attributes: person_attrs, owner: true)

    expect(result).to be_success
    occupancy = result.value!
    expect(occupancy).to be_owner
    expect(occupancy.unit).to eq(unit)
  end

  it "admin registers the responsible of a Unit directly, without an owner registered first" do
    result = service.call(actor: admin_user, unit: unit, person_attributes: person_attrs, responsible: true)

    expect(result).to be_success
    expect(result.value!).to be_responsible
  end

  it "owner delegates responsible on their own Unit" do
    owner = owner_user_for(unit)

    result = service.call(actor: owner, unit: unit, person_attributes: person_attrs, responsible: true)

    expect(result).to be_success
    expect(result.value!).to be_responsible
  end

  it "owner cannot define responsible on a different Unit" do
    owner = owner_user_for(create(:unit, building: create(:building, condominium: condominium)))

    result = service.call(actor: owner, unit: unit, person_attributes: person_attrs, responsible: true)

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end

  it "responsible registers a plain occupant on their own Unit" do
    responsible = responsible_user_for(unit)

    result = service.call(actor: responsible, unit: unit, person_attributes: person_attrs)

    expect(result).to be_success
    occupancy = result.value!
    expect(occupancy.owner?).to be(false)
    expect(occupancy.responsible?).to be(false)
  end

  it "a plain occupant cannot register anyone" do
    plain_user = create(:user)
    plain_person = create(:person, condominium: condominium, user: plain_user)
    create(:occupancy, unit: unit, person: plain_person)

    result = service.call(actor: plain_user, unit: unit, person_attributes: person_attrs(cpf: valid_cpf(2)))

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end

  it "reuses an existing Person by CPF instead of creating a duplicate" do
    admin = admin_user
    cpf = valid_cpf
    first_unit = unit
    second_unit = create(:unit, building: building)

    service.call(actor: admin, unit: first_unit, person_attributes: person_attrs(cpf: cpf), owner: true)

    expect do
      service.call(actor: admin, unit: second_unit, person_attributes: person_attrs(cpf: cpf), owner: true)
    end.not_to change(Registry::Person, :count)
  end

  it "rejects registering an existing service_provider Person as an occupant" do
    admin = admin_user
    provider = create(:person, condominium: condominium, type: "service_provider", cpf: valid_cpf)

    result = service.call(actor: admin, unit: unit, person_attributes: { name: provider.name, cpf: provider.cpf }, owner: true)

    expect(result).to be_failure
    expect(result.failure).to eq(:person_type_mismatch)
  end

  describe "grant_access" do
    it "requires an email" do
      result = service.call(actor: admin_user, unit: unit, person_attributes: person_attrs, owner: true, grant_access: true)

      expect(result).to be_failure
      expect(result.failure).to eq(:email_required)
    end

    it "creates an Invitation and stores pending_invitation_id on the Person" do
      result = service.call(
        actor: admin_user, unit: unit, person_attributes: person_attrs, owner: true,
        grant_access: true, email: "dono@example.com"
      )

      expect(result).to be_success
      person = result.value!.person
      expect(person.pending_invitation_id).to be_present

      invitation = Tenancy::Invitation.find(person.pending_invitation_id)
      expect(invitation.email).to eq("dono@example.com")
      expect(invitation.role).to eq("resident")
    end

    it "does not require an email when grant_access is false" do
      result = service.call(actor: admin_user, unit: unit, person_attributes: person_attrs, owner: true)

      expect(result).to be_success
      expect(result.value!.person.pending_invitation_id).to be_nil
    end

    it "rejects granting access to an email that already has a Membership" do
      existing_user = create(:user, email: "ja-membro@example.com")
      create(:membership, user: existing_user, condominium: create(:condominium), role: "resident", status: "active")

      result = service.call(
        actor: admin_user, unit: unit, person_attributes: person_attrs, owner: true,
        grant_access: true, email: "ja-membro@example.com"
      )

      expect(result).to be_failure
      expect(result.failure).to eq(:email_already_member)
      expect(Tenancy::Invitation.count).to eq(0)
    end
  end
end
