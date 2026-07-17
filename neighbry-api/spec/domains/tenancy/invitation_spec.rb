# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::Invitation, type: :model do
  subject(:invitation) { build(:invitation) }

  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:expires_at) }

  it "generates a unique token on create" do
    invitation.save!
    expect(invitation.token).to be_present
  end

  describe "#expired?" do
    it "is true when expires_at is in the past" do
      invitation.expires_at = 1.day.ago
      expect(invitation).to be_expired
    end

    it "is false when expires_at is in the future" do
      invitation.expires_at = 1.day.from_now
      expect(invitation).not_to be_expired
    end
  end

  describe "#accepted?" do
    it "is false when accepted_at is nil" do
      expect(invitation).not_to be_accepted
    end

    it "is true when accepted_at is present" do
      invitation.accepted_at = Time.current
      expect(invitation).to be_accepted
    end
  end
end
