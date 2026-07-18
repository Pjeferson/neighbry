# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::CicloCobranca, type: :model do
  subject(:ciclo) { build(:ciclo_cobranca) }

  it { is_expected.to belong_to(:condominium) }

  it "truncates competencia to the first day of the month" do
    ciclo = build(:ciclo_cobranca, competencia: Date.new(2026, 7, 17))
    ciclo.valid?

    expect(ciclo.competencia).to eq(Date.new(2026, 7, 1))
  end

  it "defaults to status gerando" do
    expect(create(:ciclo_cobranca)).to be_gerando
  end

  it "rejects a second ciclo for the same condominium and competencia" do
    condominium = create(:condominium)
    create(:ciclo_cobranca, condominium: condominium, competencia: Date.new(2026, 7, 5))
    duplicate = build(:ciclo_cobranca, condominium: condominium, competencia: Date.new(2026, 7, 20))

    expect(duplicate).not_to be_valid
  end

  describe "#concluir!" do
    it "moves status to concluido" do
      created = create(:ciclo_cobranca)
      created.concluir!

      expect(created.reload).to be_concluido
    end
  end
end
