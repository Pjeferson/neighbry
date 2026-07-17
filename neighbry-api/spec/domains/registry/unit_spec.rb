# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::Unit, type: :model do
  subject(:unit) { build(:unit) }

  it { is_expected.to belong_to(:building) }
  it { is_expected.to validate_presence_of(:identification) }

  it "is invalid without a building" do
    unit.building = nil
    expect(unit).not_to be_valid
  end

  it "inherits condominium_id from the building" do
    unit.valid?
    expect(unit.condominium_id).to eq(unit.building.condominium_id)
  end

  it "is invalid if condominium_id doesn't match the building's condominium" do
    unit.condominium_id = create(:condominium).id
    expect(unit).not_to be_valid
  end
end
