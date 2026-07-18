# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::DeactivateAviso do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin deactivates an Aviso" do
    admin = admin_user
    aviso = create(:aviso, condominium: condominium, criado_por: admin)

    result = service.call(actor: admin, aviso: aviso)

    expect(result).to be_success
    expect(aviso.reload.ativo).to be(false)
  end

  it "forbids a non-admin from deactivating an Aviso" do
    admin = admin_user
    aviso = create(:aviso, condominium: condominium, criado_por: admin)
    plain_user = create(:user)
    create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")

    result = service.call(actor: plain_user, aviso: aviso)

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
    expect(aviso.reload.ativo).to be(true)
  end
end
