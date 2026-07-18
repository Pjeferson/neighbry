# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommonArea::CommonArea, type: :model do
  subject(:common_area) { build(:common_area) }

  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to validate_presence_of(:nome) }
  it { is_expected.to validate_numericality_of(:capacidade).is_greater_than(0) }

  it "defaults to ativo: true" do
    expect(create(:common_area).ativo).to be(true)
  end

  it "allows editing any field after creation" do
    created = create(:common_area)
    created.nome = "Novo nome"
    created.capacidade = 100
    created.ativo = false

    expect(created).to be_valid
  end
end
