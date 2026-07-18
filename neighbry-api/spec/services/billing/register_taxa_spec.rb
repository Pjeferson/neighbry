# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::RegisterTaxa do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin registers a Taxa" do
    result = service.call(
      actor: admin_user,
      condominium: condominium,
      valor: 150.0,
      descricao: "Taxa condominial",
      data_inicio: Date.current
    )

    expect(result).to be_success
    expect(result.value!.descricao).to eq("Taxa condominial")
    expect(result.value!.ativo).to be(true)
  end

  it "forbids a non-admin from registering a Taxa" do
    plain_user = create(:user)

    result = service.call(
      actor: plain_user,
      condominium: condominium,
      valor: 150.0,
      descricao: "Taxa condominial",
      data_inicio: Date.current
    )

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end
end
