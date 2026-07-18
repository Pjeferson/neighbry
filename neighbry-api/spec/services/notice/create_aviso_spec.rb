# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::CreateAviso do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin creates an Aviso and snapshots the destinatarios" do
    admin = admin_user
    resident = create(:user)
    create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")

    result = service.call(actor: admin, condominium: condominium, titulo: "Assembleia", corpo: "Dia 10", tipo: "todos")

    expect(result).to be_success
    aviso = result.value!
    expect(aviso.leituras.pluck(:user_id)).to contain_exactly(admin.id, resident.id)
    expect(aviso.leituras.pluck(:confirmado_em)).to all(be_nil)
  end

  it "forbids a non-admin from creating an Aviso" do
    plain_user = create(:user)
    create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")

    result = service.call(actor: plain_user, condominium: condominium, titulo: "Assembleia", corpo: "Dia 10", tipo: "todos")

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end

  it "rejects an inconsistent tipo/building_id combination" do
    admin = admin_user

    result = service.call(actor: admin, condominium: condominium, titulo: "X", corpo: "Y", tipo: "todos", building_id: SecureRandom.uuid)

    expect(result).to be_failure
  end
end
