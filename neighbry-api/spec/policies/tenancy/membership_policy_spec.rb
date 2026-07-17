# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::MembershipPolicy do
  let(:condominium) { create(:condominium) }
  let(:record) { build(:membership, condominium: condominium) }

  around do |example|
    Tenancy::Current.condominium = condominium
    example.run
    Tenancy::Current.reset
  end

  subject(:policy) { described_class.new(user, record) }

  context "when the user has an active admin Membership in the current Condominium" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits create, update and destroy" do
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end
  end

  context "when the user has a non-admin Membership in the current Condominium" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "resident", status: "active") }

    it "forbids create, update and destroy" do
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end

  context "when the user's admin Membership is in a different Condominium" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: create(:condominium), role: "admin", status: "active") }

    it "forbids create" do
      expect(policy.create?).to be(false)
    end
  end

  context "when the user's admin Membership is revoked" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "revoked") }

    it "forbids create" do
      expect(policy.create?).to be(false)
    end
  end

  context "when there is no user" do
    let(:user) { nil }

    it "forbids create" do
      expect(policy.create?).to be(false)
    end
  end
end
