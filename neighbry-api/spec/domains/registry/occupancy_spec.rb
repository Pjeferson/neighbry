# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::Occupancy, type: :model do
  subject(:occupancy) { build(:occupancy) }

  it { is_expected.to belong_to(:unit) }
  it { is_expected.to belong_to(:person) }

  it "does not allow start_date to be cleared on an existing record" do
    created = create(:occupancy)
    created.start_date = nil

    expect(created).not_to be_valid
  end

  it "inherits condominium_id from the unit" do
    unit = create(:unit)
    persisted = build(:occupancy, unit: unit)

    persisted.valid?

    expect(persisted.condominium_id).to eq(unit.condominium_id)
  end

  it "sets start_date to today by default" do
    created = create(:occupancy, start_date: nil)
    expect(created.start_date).to eq(Date.current)
  end

  describe "#active?" do
    it "is true when end_date is nil" do
      expect(occupancy).to be_active
    end

    it "is false when end_date is present" do
      occupancy.end_date = Date.current
      expect(occupancy).not_to be_active
    end
  end

  describe "#end!" do
    it "sets end_date without deleting the record" do
      created = create(:occupancy)
      created.end!(date: Date.current)

      expect(created.reload.end_date).to eq(Date.current)
      expect(Registry::Occupancy.exists?(created.id)).to be(true)
    end
  end

  it "rejects owner and responsible both true on the same Occupancy" do
    occupancy.owner = true
    occupancy.responsible = true

    expect(occupancy).not_to be_valid
  end

  it "rejects a Person from a different condominium than the Unit" do
    occupancy.person = create(:person, condominium: create(:condominium))

    expect(occupancy).not_to be_valid
  end

  describe "owner uniqueness per Unit" do
    let(:unit) { create(:unit) }

    it "rejects a second active owner on the same Unit" do
      create(:occupancy, unit: unit, owner: true)
      second = build(:occupancy, unit: unit, owner: true)

      expect(second).not_to be_valid
    end

    it "allows a new owner once the previous one is inactive" do
      previous = create(:occupancy, unit: unit, owner: true)
      previous.end!

      second = build(:occupancy, unit: unit, owner: true)

      expect(second).to be_valid
    end
  end

  describe "responsible uniqueness per Unit" do
    let(:unit) { create(:unit) }

    it "rejects a second active responsible on the same Unit" do
      create(:occupancy, unit: unit, responsible: true)
      second = build(:occupancy, unit: unit, responsible: true)

      expect(second).not_to be_valid
    end
  end

  it "allows the same Person to have Occupancy in different Unit of the same condominium" do
    existing = create(:occupancy)
    other_unit = create(:unit, building: create(:building, condominium: existing.person.condominium))

    second = build(:occupancy, unit: other_unit, person: existing.person)

    expect(second).to be_valid
  end

  it "rejects a duplicate active Occupancy for the same Person and Unit" do
    existing = create(:occupancy)

    duplicate = build(:occupancy, unit: existing.unit, person: existing.person)

    expect(duplicate).not_to be_valid
  end
end
