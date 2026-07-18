# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::FaturaPolicy do
  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }

  subject(:policy) { described_class.new(user, unit) }

  context "when the user is admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits viewing Faturas of any Unit in the condominium" do
      expect(policy.view?).to be(true)
    end
  end

  context "when the user has an active Occupancy in the Unit, regardless of role" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: unit, person: person, owner: false, responsible: false) }

    it "permits viewing Faturas of that Unit" do
      expect(policy.view?).to be(true)
    end
  end

  context "when the user has an active Occupancy in a different Unit" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }
    let(:other_unit) { create(:unit, building: building) }

    before { create(:occupancy, unit: other_unit, person: person) }

    it "forbids viewing Faturas of this Unit" do
      expect(policy.view?).to be(false)
    end
  end

  context "when the user has no Occupancy anywhere" do
    let(:user) { create(:user) }

    it "forbids viewing Faturas" do
      expect(policy.view?).to be(false)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "forbids viewing Faturas" do
      expect(policy.view?).to be(false)
    end
  end
end
