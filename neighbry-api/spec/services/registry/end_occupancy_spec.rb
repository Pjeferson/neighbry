# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::EndOccupancy do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  def occupant_user(target_unit, owner: false, responsible: false)
    user = create(:user)
    person = create(:person, condominium: target_unit.condominium, user: user)
    create(:occupancy, unit: target_unit, person: person, owner: owner, responsible: responsible)
    user
  end

  describe "ending an owner Occupancy" do
    it "admin can end it" do
      occupancy = create(:occupancy, unit: unit, owner: true)

      result = service.call(actor: admin_user, occupancy: occupancy)

      expect(result).to be_success
      expect(occupancy.reload).not_to be_active
    end

    it "the owner cannot end their own Occupancy" do
      owner = occupant_user(unit, owner: true)
      occupancy = Registry::Occupancy.find_by(unit: unit, owner: true)

      result = service.call(actor: owner, occupancy: occupancy)

      expect(result).to be_failure
      expect(result.failure).to eq(:unauthorized)
      expect(occupancy.reload).to be_active
    end
  end

  describe "ending a responsible Occupancy" do
    it "the owner of the unit can end it" do
      owner = occupant_user(unit, owner: true)
      responsible_occupancy = create(:occupancy, unit: unit, responsible: true)

      result = service.call(actor: owner, occupancy: responsible_occupancy)

      expect(result).to be_success
      expect(responsible_occupancy.reload).not_to be_active
    end

    it "the responsible cannot end their own Occupancy" do
      responsible = occupant_user(unit, responsible: true)
      occupancy = Registry::Occupancy.find_by(unit: unit, responsible: true)

      result = service.call(actor: responsible, occupancy: occupancy)

      expect(result).to be_failure
      expect(result.failure).to eq(:unauthorized)
    end
  end

  describe "ending a plain occupant Occupancy" do
    it "admin, owner or responsible can end it" do
      responsible = occupant_user(unit, responsible: true)
      plain_occupancy = create(:occupancy, unit: unit)

      result = service.call(actor: responsible, occupancy: plain_occupancy)

      expect(result).to be_success
      expect(plain_occupancy.reload).not_to be_active
    end

    it "another plain occupant cannot end it" do
      occupant_user(unit)
      other_plain = create(:user)
      other_person = create(:person, condominium: condominium, user: other_plain)
      create(:occupancy, unit: create(:unit, building: building), person: other_person)

      plain_occupancy = create(:occupancy, unit: unit)

      result = service.call(actor: other_plain, occupancy: plain_occupancy)

      expect(result).to be_failure
      expect(result.failure).to eq(:unauthorized)
    end
  end
end
