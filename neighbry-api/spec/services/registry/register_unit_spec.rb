# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::RegisterUnit do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin registers a Unit" do
    result = service.call(actor: admin_user, building: building, identification: "101")

    expect(result).to be_success
    expect(result.value!.identification).to eq("101")
  end

  it "forbids a non-admin from registering a Unit" do
    plain_user = create(:user)

    result = service.call(actor: plain_user, building: building, identification: "101")

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end
end
