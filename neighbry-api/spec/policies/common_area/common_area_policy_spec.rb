# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommonArea::CommonAreaPolicy do
  let(:condominium) { create(:condominium) }

  subject(:policy) { described_class.new(user, condominium) }

  context "when the user is admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits create, update and list" do
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.list?).to be(true)
    end
  end

  context "when the user is a resident" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "resident", status: "active") }

    it "forbids create and update but permits list" do
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.list?).to be(true)
    end
  end

  context "when the user has no Membership in the condominium" do
    let(:user) { create(:user) }

    it "forbids everything" do
      expect(policy.create?).to be(false)
      expect(policy.list?).to be(false)
    end
  end
end
