# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::ReconcilePersonUser do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:person) { create(:person, condominium: condominium, pending_invitation_id: SecureRandom.uuid) }

  it "fills user_id and clears pending_invitation_id when the invitation_id matches" do
    user = create(:user)

    service.call(invitation_id: person.pending_invitation_id, user_id: user.id)

    expect(person.reload.user_id).to eq(user.id)
    expect(person.reload.pending_invitation_id).to be_nil
  end

  it "does nothing when no Person is waiting for that invitation_id" do
    user = create(:user)

    expect { service.call(invitation_id: SecureRandom.uuid, user_id: user.id) }.not_to raise_error
  end

  it "is a no-op the second time it runs for the same invitation_id (idempotent)" do
    user = create(:user)
    invitation_id = person.pending_invitation_id

    service.call(invitation_id: invitation_id, user_id: user.id)
    expect { service.call(invitation_id: invitation_id, user_id: user.id) }.not_to raise_error
  end
end
