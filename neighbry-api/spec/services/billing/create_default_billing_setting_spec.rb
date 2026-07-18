# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::CreateDefaultBillingSetting do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  it "creates a default setting for the condominium" do
    setting = service.call(condominium_id: condominium.id)

    expect(setting.dia_cobranca).to eq(described_class::DEFAULT_DIA_COBRANCA)
    expect(setting.dias_para_vencimento).to eq(described_class::DEFAULT_DIAS_PARA_VENCIMENTO)
  end

  it "is idempotent for the same condominium" do
    first = service.call(condominium_id: condominium.id)
    second = service.call(condominium_id: condominium.id)

    expect(first.id).to eq(second.id)
    expect(Billing::CondominiumBillingSetting.where(condominium_id: condominium.id).count).to eq(1)
  end
end
