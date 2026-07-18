# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::GenerateMonthlyInvoicesJob do
  include ActiveSupport::Testing::TimeHelpers

  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }

  around { |example| travel_to(Date.new(2026, 7, 8)) { example.run } }

  it "generates Fatura for condominiums whose dia_cobranca has already passed this month" do
    create(:condominium_billing_setting, condominium: condominium, dia_cobranca: 5, dias_para_vencimento: 10)
    unit = create(:unit, building: building)
    create(:occupancy, unit: unit)
    create(:taxa, condominium: condominium, valor: 100, data_inicio: Date.current.beginning_of_month)

    described_class.perform_now

    ciclo = Billing::CicloCobranca.find_by(condominium: condominium)
    expect(ciclo).to be_present
    expect(ciclo).to be_concluido
    expect(ciclo.faturas.count).to eq(1)
  end

  it "does not generate a cycle for a condominium whose dia_cobranca has not arrived yet" do
    create(:condominium_billing_setting, condominium: condominium, dia_cobranca: 12, dias_para_vencimento: 10)

    described_class.perform_now

    expect(Billing::CicloCobranca.where(condominium: condominium)).to be_empty
  end

  it "is idempotent across multiple runs on the same day" do
    create(:condominium_billing_setting, condominium: condominium, dia_cobranca: 5, dias_para_vencimento: 10)
    unit = create(:unit, building: building)
    create(:occupancy, unit: unit)
    create(:taxa, condominium: condominium, valor: 100, data_inicio: Date.current.beginning_of_month)

    described_class.perform_now
    described_class.perform_now

    expect(Billing::CicloCobranca.where(condominium: condominium).count).to eq(1)
  end

  it "skips condominiums without a billing setting" do
    described_class.perform_now

    expect(Billing::CicloCobranca.where(condominium: condominium)).to be_empty
  end
end
