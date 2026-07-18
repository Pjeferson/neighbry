# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::Aviso, type: :model do
  subject(:aviso) { build(:aviso) }

  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to belong_to(:criado_por) }
  it { is_expected.to validate_presence_of(:titulo) }
  it { is_expected.to validate_presence_of(:corpo) }

  describe "validação condicional de building_id/unit_id por tipo" do
    it "rejects torre without building_id" do
      aviso = build(:aviso, tipo: "torre", building_id: nil)
      expect(aviso).not_to be_valid
    end

    it "accepts torre with building_id and rejects unit_id present" do
      building = create(:building)
      valid_aviso = build(:aviso, tipo: "torre", building_id: building.id, condominium: building.condominium)
      expect(valid_aviso).to be_valid

      unit = create(:unit, building: building)
      invalid_aviso = build(:aviso, tipo: "torre", building_id: building.id, unit_id: unit.id, condominium: building.condominium)
      expect(invalid_aviso).not_to be_valid
    end

    it "rejects unidade without unit_id" do
      aviso = build(:aviso, tipo: "unidade", unit_id: nil)
      expect(aviso).not_to be_valid
    end

    it "accepts unidade with unit_id and rejects building_id present" do
      unit = create(:unit)
      valid_aviso = build(:aviso, tipo: "unidade", unit_id: unit.id, condominium: unit.condominium)
      expect(valid_aviso).to be_valid

      invalid_aviso = build(:aviso, tipo: "unidade", unit_id: unit.id, building_id: unit.building_id, condominium: unit.condominium)
      expect(invalid_aviso).not_to be_valid
    end

    it "rejects todos with building_id or unit_id present" do
      building = create(:building)
      expect(build(:aviso, tipo: "todos", building_id: building.id, condominium: building.condominium)).not_to be_valid
    end
  end

  describe "immutability after creation" do
    it "rejects changing titulo" do
      created = create(:aviso)
      created.titulo = "Outro título"

      expect(created).not_to be_valid
      expect(created.errors[:titulo]).to include("cannot be changed after creation")
    end

    it "rejects changing tipo" do
      created = create(:aviso, tipo: "todos")
      created.tipo = "moradores"

      expect(created).not_to be_valid
    end

    it "allows changing ativo" do
      created = create(:aviso)
      created.ativo = false

      expect(created).to be_valid
    end
  end
end
