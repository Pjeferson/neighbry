# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Fatura, type: :model do
  subject(:fatura) { build(:fatura) }

  it { is_expected.to belong_to(:unit) }
  it { is_expected.to belong_to(:ciclo_cobranca) }
  it { is_expected.to validate_presence_of(:data_vencimento) }

  it "is invalid without any Cobranca" do
    fatura.cobrancas.clear
    expect(fatura).not_to be_valid
  end

  it "rejects a second Fatura for the same Unit within the same CicloCobranca" do
    unit = create(:unit)
    ciclo = create(:ciclo_cobranca, condominium: unit.condominium)
    create(:fatura, unit: unit, condominium: unit.condominium, ciclo_cobranca: ciclo)
    duplicate = build(:fatura, unit: unit, condominium: unit.condominium, ciclo_cobranca: ciclo)

    expect(duplicate).not_to be_valid
  end

  it "defaults to status pendente" do
    expect(create(:fatura)).to be_pendente
  end

  describe "#total" do
    it "sums the value of its Cobrancas" do
      fatura = create(:fatura)
      taxa = create(:taxa, condominium: fatura.condominium)
      create(:cobranca, fatura: fatura, condominium: fatura.condominium, taxa: taxa, valor: 50)

      expect(fatura.total).to eq(fatura.cobrancas.sum(:valor))
    end
  end

  describe "#atrasada?" do
    it "is true when pendente and past due" do
      fatura = create(:fatura, data_vencimento: Date.current - 1.day)
      expect(fatura).to be_atrasada
    end

    it "is false when pendente but not yet due" do
      fatura = create(:fatura, data_vencimento: Date.current + 1.day)
      expect(fatura).not_to be_atrasada
    end

    it "is false when already paid, even if past due" do
      fatura = create(:fatura, data_vencimento: Date.current - 1.day, status: "pago")
      expect(fatura).not_to be_atrasada
    end
  end
end
