# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::GenerateInvoicesForCycle do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }

  before { create(:condominium_billing_setting, condominium: condominium, dias_para_vencimento: 10) }

  def unit_with_occupant
    unit = create(:unit, building: building)
    create(:occupancy, unit: unit)
    unit
  end

  it "generates one Fatura per active unit, rateado igualmente" do
    unit_a = unit_with_occupant
    unit_b = unit_with_occupant
    create(:taxa, condominium: condominium, valor: 400, data_inicio: Date.current.beginning_of_month)
    ciclo = create(:ciclo_cobranca, condominium: condominium, competencia: Date.current.beginning_of_month)

    service.call(ciclo_cobranca: ciclo)

    expect(ciclo.faturas.pluck(:unit_id)).to contain_exactly(unit_a.id, unit_b.id)
    expect(ciclo.faturas.map(&:total)).to all(eq(200))
    expect(ciclo.reload).to be_concluido
  end

  it "does not bill a Unit without any active Occupancy" do
    unit_with_occupant
    create(:unit, building: building) # vaga, sem ocupante
    create(:taxa, condominium: condominium, valor: 100, data_inicio: Date.current.beginning_of_month)
    ciclo = create(:ciclo_cobranca, condominium: condominium, competencia: Date.current.beginning_of_month)

    service.call(ciclo_cobranca: ciclo)

    expect(ciclo.faturas.count).to eq(1)
  end

  it "bills a Unit occupied only by a plain resident (no owner/responsible)" do
    unit = unit_with_occupant
    create(:taxa, condominium: condominium, valor: 100, data_inicio: Date.current.beginning_of_month)
    ciclo = create(:ciclo_cobranca, condominium: condominium, competencia: Date.current.beginning_of_month)

    service.call(ciclo_cobranca: ciclo)

    expect(ciclo.faturas.pluck(:unit_id)).to contain_exactly(unit.id)
  end

  it "does not generate any Fatura when no Taxa is applicable" do
    unit_with_occupant
    ciclo = create(:ciclo_cobranca, condominium: condominium, competencia: Date.current.beginning_of_month)

    service.call(ciclo_cobranca: ciclo)

    expect(ciclo.faturas.count).to eq(0)
    expect(ciclo.reload).to be_concluido
  end

  it "resumes a partially generated cycle without duplicating existing Fatura" do
    unit_a = unit_with_occupant
    unit_b = unit_with_occupant
    taxa = create(:taxa, condominium: condominium, valor: 200, data_inicio: Date.current.beginning_of_month)
    ciclo = create(:ciclo_cobranca, condominium: condominium, competencia: Date.current.beginning_of_month, status: "gerando")

    # Simula falha parcial: Fatura de unit_a já foi gerada antes do crash.
    fatura_a = Billing::Fatura.new(
      condominium: condominium, unit: unit_a, ciclo_cobranca: ciclo, data_vencimento: Date.current + 10.days
    )
    fatura_a.cobrancas.build(condominium: condominium, taxa: taxa, valor: 100)
    fatura_a.save!

    service.call(ciclo_cobranca: ciclo)

    expect(ciclo.faturas.where(unit_id: unit_a.id).count).to eq(1)
    expect(ciclo.faturas.where(unit_id: unit_b.id).count).to eq(1)
    expect(ciclo.reload).to be_concluido
  end
end
