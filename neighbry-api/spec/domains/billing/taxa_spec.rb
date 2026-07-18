# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Taxa, type: :model do
  subject(:taxa) { build(:taxa) }

  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to validate_presence_of(:descricao) }
  it { is_expected.to validate_presence_of(:data_inicio) }
  it { is_expected.to validate_numericality_of(:valor).is_greater_than(0) }

  describe "immutability after creation" do
    it "rejects changing valor" do
      created = create(:taxa)
      created.valor += 1

      expect(created).not_to be_valid
      expect(created.errors[:valor]).to include("cannot be changed after creation")
    end

    it "rejects changing data_inicio" do
      created = create(:taxa)
      created.data_inicio += 1.day

      expect(created).not_to be_valid
    end

    it "rejects changing data_fim" do
      created = create(:taxa, data_fim: Date.current + 1.month)
      created.data_fim += 1.day

      expect(created).not_to be_valid
    end

    it "allows changing ativo" do
      created = create(:taxa)
      created.ativo = false

      expect(created).to be_valid
    end
  end

  describe "#aplicavel?" do
    it "is true within data_inicio/data_fim when ativo" do
      taxa = build(:taxa, data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 6, 1), ativo: true)
      expect(taxa.aplicavel?(Date.new(2026, 3, 1))).to be true
    end

    it "is false before data_inicio" do
      taxa = build(:taxa, data_inicio: Date.new(2026, 3, 1))
      expect(taxa.aplicavel?(Date.new(2026, 1, 1))).to be false
    end

    it "is false after data_fim" do
      taxa = build(:taxa, data_inicio: Date.new(2026, 1, 1), data_fim: Date.new(2026, 3, 1))
      expect(taxa.aplicavel?(Date.new(2026, 4, 1))).to be false
    end

    it "is true indefinitely when data_fim is nil" do
      taxa = build(:taxa, data_inicio: Date.new(2026, 1, 1), data_fim: nil)
      expect(taxa.aplicavel?(Date.new(2030, 1, 1))).to be true
    end

    it "is false when ativo is false" do
      taxa = build(:taxa, ativo: false)
      expect(taxa.aplicavel?(taxa.data_inicio)).to be false
    end
  end
end
