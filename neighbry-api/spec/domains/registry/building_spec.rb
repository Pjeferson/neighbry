# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::Building, type: :model do
  subject(:building) { build(:building) }

  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to validate_presence_of(:name) }

  it "is invalid without a condominium" do
    building.condominium = nil
    expect(building).not_to be_valid
  end
end
