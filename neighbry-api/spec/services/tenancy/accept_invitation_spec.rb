# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::AcceptInvitation do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:invitation) { create(:invitation, condominium: condominium, email: "convidado@example.com") }

  it "creates a User and activates the Membership when accepted" do
    result = service.call(token: invitation.token, password: "password123", name: "Convidado")

    expect(result).to be_success
    membership = result.value!
    expect(membership).to be_active
    expect(membership.condominium).to eq(condominium)
    expect(membership.role).to eq("resident")

    user = User.find_by(email: "convidado@example.com")
    expect(user).to be_present
    expect(invitation.reload).to be_accepted
  end

  it "reuses an existing User by email instead of creating a duplicate" do
    existing_user = create(:user, email: "convidado@example.com")

    result = service.call(token: invitation.token, password: "ignored", name: "ignored")

    expect(result).to be_success
    expect(result.value!.user).to eq(existing_user)
  end

  it "fails for an unknown token" do
    result = service.call(token: "invalido", password: "password123", name: "Convidado")

    expect(result).to be_failure
    expect(result.failure).to eq(:not_found)
  end

  it "fails for an expired invitation" do
    invitation.update!(expires_at: 1.day.ago)

    result = service.call(token: invitation.token, password: "password123", name: "Convidado")

    expect(result).to be_failure
    expect(result.failure).to eq(:expired)
  end

  it "fails if the invitation was already accepted" do
    invitation.update!(accepted_at: 1.hour.ago)

    result = service.call(token: invitation.token, password: "password123", name: "Convidado")

    expect(result).to be_failure
    expect(result.failure).to eq(:already_accepted)
  end

  it "fails if the User already has a Membership (1:1)" do
    existing_user = create(:user, email: "convidado@example.com")
    create(:membership, user: existing_user)

    result = service.call(token: invitation.token, password: "ignored", name: "ignored")

    expect(result).to be_failure
    expect(result.failure).to eq(:already_member)
  end
end
