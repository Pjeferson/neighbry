# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::BuildingPolicy do
  let(:condominium) { create(:condominium) }

  subject(:policy) { described_class.new(user, condominium) }

  context "when the user is admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits creating a Building" do
      expect(policy.create?).to be(true)
    end
  end

  context "when the user is owner of some Unit in the condominium" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person, owner: true) }

    it "forbids creating a Building" do
      expect(policy.create?).to be(false)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "forbids creating a Building" do
      expect(policy.create?).to be(false)
    end
  end
end
