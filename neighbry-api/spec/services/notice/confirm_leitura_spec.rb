# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::ConfirmLeitura do
  subject(:service) { described_class.new }

  let(:aviso) { create(:aviso) }
  let(:destinatario) { create(:user) }
  let!(:leitura) { create(:leitura, aviso: aviso, user: destinatario) }

  it "confirms leitura for the destinatario" do
    result = service.call(actor: destinatario, aviso: aviso)

    expect(result).to be_success
    expect(result.value!.confirmado_em).to be_present
  end

  it "is idempotent — confirming twice does not create a duplicate row" do
    service.call(actor: destinatario, aviso: aviso)
    result = service.call(actor: destinatario, aviso: aviso)

    expect(result).to be_success
    expect(Notice::Leitura.where(aviso: aviso, user: destinatario).count).to eq(1)
  end

  it "rejects confirmation from a User who is not a destinatario" do
    outsider = create(:user)

    result = service.call(actor: outsider, aviso: aviso)

    expect(result).to be_failure
    expect(result.failure).to eq(:not_a_destinatario)
  end

  it "rejects confirmation when the Aviso is inactive" do
    aviso.update!(ativo: false)

    result = service.call(actor: destinatario, aviso: aviso)

    expect(result).to be_failure
    expect(result.failure).to eq(:aviso_inativo)
    expect(leitura.reload.confirmado_em).to be_nil
  end
end
