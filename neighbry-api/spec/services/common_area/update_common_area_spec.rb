# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommonArea::UpdateCommonArea do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "admin edits any field, including after creation" do
    admin = admin_user
    common_area = create(:common_area, condominium: condominium)

    result = service.call(actor: admin, common_area: common_area, attributes: { nome: "Novo nome", ativo: false })

    expect(result).to be_success
    expect(result.value!.nome).to eq("Novo nome")
    expect(result.value!.ativo).to be(false)
  end

  it "forbids a non-admin from editing" do
    plain_user = create(:user)
    create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
    common_area = create(:common_area, condominium: condominium)

    result = service.call(actor: plain_user, common_area: common_area, attributes: { nome: "Novo nome" })

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end
end
