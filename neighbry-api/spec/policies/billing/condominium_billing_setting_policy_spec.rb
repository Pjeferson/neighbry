# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::CondominiumBillingSettingPolicy do
  let(:condominium) { create(:condominium) }

  subject(:policy) { described_class.new(user, condominium) }

  context "when the user is admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits updating the setting" do
      expect(policy.update?).to be(true)
    end
  end

  context "when the user is not admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "resident", status: "active") }

    it "forbids updating the setting" do
      expect(policy.update?).to be(false)
    end
  end
end
