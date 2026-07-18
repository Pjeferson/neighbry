# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::PagamentoPolicy do
  let(:condominium) { create(:condominium) }

  subject(:policy) { described_class.new(user, condominium) }

  context "when the user is admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits confirming a payment" do
      expect(policy.confirm?).to be(true)
    end
  end

  context "when the user is owner of some Unit in the condominium" do
    let(:user) { create(:user) }
    let(:person) { create(:person, condominium: condominium, user: user) }

    before { create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: person, owner: true) }

    it "forbids confirming a payment" do
      expect(policy.confirm?).to be(false)
    end
  end
end
