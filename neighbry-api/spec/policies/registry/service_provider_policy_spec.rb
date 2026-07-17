# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::ServiceProviderPolicy do
  let(:condominium) { create(:condominium) }

  subject(:policy) { described_class.new(user, condominium) }

  context "when the user is admin in the condominium" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits creating a service provider" do
      expect(policy.create?).to be(true)
    end
  end

  context "when the user is owner of some unit in the condominium" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person, owner: true) }

    it "permits creating a service provider" do
      expect(policy.create?).to be(true)
    end
  end

  context "when the user is responsible of some unit in the condominium" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person, responsible: true) }

    it "permits creating a service provider" do
      expect(policy.create?).to be(true)
    end
  end

  context "when the user is a plain occupant with no owner/responsible flag" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person) }

    it "forbids creating a service provider" do
      expect(policy.create?).to be(false)
    end
  end

  context "when the user's owner role is in a different condominium" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: create(:condominium), user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: person.condominium)), person: person, owner: true) }

    it "forbids creating a service provider" do
      expect(policy.create?).to be(false)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "forbids creating a service provider" do
      expect(policy.create?).to be(false)
    end
  end
end
