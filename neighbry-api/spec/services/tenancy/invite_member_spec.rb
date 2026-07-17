# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::InviteMember do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  it "creates a pending Invitation with a token and expiration" do
    result = service.call(condominium: condominium, email: "novo@example.com", role: "resident")

    expect(result).to be_success
    invitation = result.value!
    expect(invitation).to be_persisted
    expect(invitation.token).to be_present
    expect(invitation.expires_at).to be_within(1.minute).of(described_class::EXPIRATION_PERIOD.from_now)
    expect(invitation.accepted_at).to be_nil
  end

  it "does not accept a password parameter" do
    expect(service.method(:call).parameters.map(&:last)).not_to include(:password)
  end

  it "fails with invalid attributes" do
    result = service.call(condominium: condominium, email: "", role: "resident")

    expect(result).to be_failure
  end
end
