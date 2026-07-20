# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::RegisterServiceProvider do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def person_attrs(cpf: valid_cpf)
    { name: "Prestador", cpf: cpf }
  end

  # Offset alto pra nunca colidir com a sequence própria da factory :person.
  def valid_cpf(seed = 1)
    base = format("%09d", 600_000_000 + seed)
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

  def owner_user
    user = create(:user)
    person = create(:person, condominium: condominium, user: user)
    create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person, owner: true)
    user
  end

  it "admin registers a service provider" do
    result = service.call(actor: admin_user, condominium: condominium, person_attributes: person_attrs)

    expect(result).to be_success
    person = result.value!
    expect(person).to be_service_provider
  end

  it "owner registers a service provider" do
    result = service.call(actor: owner_user, condominium: condominium, person_attributes: person_attrs)

    expect(result).to be_success
  end

  it "never creates an Occupancy for the service provider" do
    result = service.call(actor: admin_user, condominium: condominium, person_attributes: person_attrs)

    expect(Registry::Occupancy.where(person_id: result.value!.id)).to be_empty
  end

  it "a plain occupant without owner/responsible cannot register a service provider" do
    plain_user = create(:user)
    plain_person = create(:person, condominium: condominium, user: plain_user)
    create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: plain_person)

    result = service.call(actor: plain_user, condominium: condominium, person_attributes: person_attrs)

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end

  it "rejects reusing a CPF already registered as resident" do
    resident = create(:person, condominium: condominium, type: "resident", cpf: valid_cpf)

    result = service.call(actor: admin_user, condominium: condominium, person_attributes: { name: resident.name, cpf: resident.cpf })

    expect(result).to be_failure
    expect(result.failure).to eq(:person_type_mismatch)
  end

  describe "grant_access" do
    it "requires an email" do
      result = service.call(actor: admin_user, condominium: condominium, person_attributes: person_attrs, grant_access: true)

      expect(result).to be_failure
      expect(result.failure).to eq(:email_required)
    end

    it "creates an Invitation and stores pending_invitation_id" do
      result = service.call(
        actor: admin_user, condominium: condominium, person_attributes: person_attrs,
        grant_access: true, email: "prestador@example.com"
      )

      expect(result).to be_success
      expect(result.value!.pending_invitation_id).to be_present
    end

    it "grants role: service_provider, not resident" do
      result = service.call(
        actor: admin_user, condominium: condominium, person_attributes: person_attrs,
        grant_access: true, email: "prestador@example.com"
      )

      invitation = Tenancy::Invitation.find(result.value!.pending_invitation_id)
      expect(invitation).to be_service_provider
    end

    it "rejects granting access to an email that already has a Membership" do
      existing_user = create(:user, email: "ja-membro@example.com")
      create(:membership, user: existing_user, condominium: create(:condominium), role: "resident", status: "active")

      result = service.call(
        actor: admin_user, condominium: condominium, person_attributes: person_attrs,
        grant_access: true, email: "ja-membro@example.com"
      )

      expect(result).to be_failure
      expect(result.failure).to eq(:email_already_member)
      expect(Tenancy::Invitation.count).to eq(0)
    end
  end
end
