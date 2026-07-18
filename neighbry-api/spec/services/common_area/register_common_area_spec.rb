# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommonArea::RegisterCommonArea do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin registers a CommonArea" do
    result = service.call(actor: admin_user, condominium: condominium, nome: "Piscina", capacidade: 30)

    expect(result).to be_success
    expect(result.value!.nome).to eq("Piscina")
    expect(result.value!.ativo).to be(true)
  end

  it "forbids a non-admin from registering a CommonArea" do
    plain_user = create(:user)
    create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")

    result = service.call(actor: plain_user, condominium: condominium, nome: "Piscina", capacidade: 30)

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end
end
