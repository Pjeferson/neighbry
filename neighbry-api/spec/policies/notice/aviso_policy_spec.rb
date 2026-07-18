# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::AvisoPolicy do
  let(:condominium) { create(:condominium) }

  subject(:policy) { described_class.new(user, condominium) }

  context "when the user is admin" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

    it "permits creating an Aviso" do
      expect(policy.create?).to be(true)
    end

    it "permits viewing the painel" do
      expect(policy.view_painel?).to be(true)
    end
  end

  context "when the user is manager (staff, not admin)" do
    let(:user) { create(:user) }

    before { create(:membership, user: user, condominium: condominium, role: "manager", status: "active") }

    it "forbids creating an Aviso" do
      expect(policy.create?).to be(false)
    end

    it "forbids viewing the painel" do
      expect(policy.view_painel?).to be(false)
    end
  end
end
