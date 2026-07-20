# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::Membership, type: :model do
  subject(:membership) { build(:membership) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to validate_uniqueness_of(:user_id).ignoring_case_sensitivity }

  describe "role" do
    it "accepts the defined roles" do
      %w[admin manager service_provider resident].each do |role|
        membership.role = role
        expect(membership).to be_valid
      end
    end

    it "rejects a role outside the enum" do
      membership.role = "sindico"
      expect(membership).not_to be_valid
    end
  end

  describe "status" do
    it "defaults to active" do
      expect(described_class.new.status).to eq("active")
    end

    it "rejects a status outside the enum" do
      membership.status = "pending"
      expect(membership).not_to be_valid
    end
  end

  describe "uniqueness" do
    it "rejects a second Membership for the same User" do
      existing = create(:membership)
      duplicate = build(:membership, user: existing.user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end
end
