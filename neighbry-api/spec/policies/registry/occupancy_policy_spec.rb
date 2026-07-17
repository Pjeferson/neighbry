# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::OccupancyPolicy do
  let(:unit) { create(:unit) }
  let(:condominium) { unit.condominium }

  subject(:policy) { described_class.new(user, unit) }

  context "when the user is admin (Tenancy::Membership) in the condominium" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits everything" do
      expect(policy.create_owner?).to be(true)
      expect(policy.create_responsible?).to be(true)
      expect(policy.create_occupant?).to be(true)
      expect(policy.end_owner?).to be(true)
      expect(policy.end_responsible?).to be(true)
      expect(policy.end_occupant?).to be(true)
    end
  end

  context "when the user is the owner of the unit" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: unit, person: person, owner: true) }

    it "permits registering/ending responsible and occupant, but not owner" do
      expect(policy.create_owner?).to be(false)
      expect(policy.create_responsible?).to be(true)
      expect(policy.create_occupant?).to be(true)
      expect(policy.end_owner?).to be(false)
      expect(policy.end_responsible?).to be(true)
      expect(policy.end_occupant?).to be(true)
    end
  end

  context "when the user is the responsible of the unit" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: unit, person: person, responsible: true) }

    it "permits only registering/ending a plain occupant" do
      expect(policy.create_owner?).to be(false)
      expect(policy.create_responsible?).to be(false)
      expect(policy.create_occupant?).to be(true)
      expect(policy.end_owner?).to be(false)
      expect(policy.end_responsible?).to be(false)
      expect(policy.end_occupant?).to be(true)
    end
  end

  context "when the user is owner of a different unit" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person, owner: true) }

    it "forbids everything on this unit" do
      expect(policy.create_owner?).to be(false)
      expect(policy.create_responsible?).to be(false)
      expect(policy.create_occupant?).to be(false)
    end
  end

  context "when the user has no role at all" do
    let(:user) { create(:user) }

    it "forbids everything" do
      expect(policy.create_owner?).to be(false)
      expect(policy.create_responsible?).to be(false)
      expect(policy.create_occupant?).to be(false)
      expect(policy.end_owner?).to be(false)
      expect(policy.end_responsible?).to be(false)
      expect(policy.end_occupant?).to be(false)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "forbids everything" do
      expect(policy.create_owner?).to be(false)
      expect(policy.create_occupant?).to be(false)
    end
  end
end
