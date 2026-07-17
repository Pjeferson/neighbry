# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::RegisterBuilding do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin registers a Building" do
    result = service.call(actor: admin_user, condominium: condominium, name: "Bloco A")

    expect(result).to be_success
    expect(result.value!.name).to eq("Bloco A")
  end

  it "forbids a non-admin from registering a Building" do
    plain_user = create(:user)

    result = service.call(actor: plain_user, condominium: condominium, name: "Bloco A")

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end
end
