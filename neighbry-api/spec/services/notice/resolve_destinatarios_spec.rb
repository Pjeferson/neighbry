# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::ResolveDestinatarios do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }
  let(:building) { create(:building, condominium: condominium) }

  def membership_user(role)
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: role, status: "active")
    user
  end

  describe "tipo: todos" do
    it "includes admin, staff and moradores" do
      admin = membership_user("admin")
      manager = membership_user("manager")
      doorman = membership_user("doorman")
      resident = membership_user("resident")

      result = service.call(tipo: "todos", condominium_id: condominium.id)

      expect(result).to contain_exactly(admin.id, manager.id, doorman.id, resident.id)
    end
  end

  describe "tipo: moradores" do
    it "includes only role: resident" do
      membership_user("admin")
      resident = membership_user("resident")

      result = service.call(tipo: "moradores", condominium_id: condominium.id)

      expect(result).to contain_exactly(resident.id)
    end
  end

  describe "tipo: staff" do
    it "includes admin, manager and doorman, excludes resident" do
      admin = membership_user("admin")
      manager = membership_user("manager")
      doorman = membership_user("doorman")
      membership_user("resident")

      result = service.call(tipo: "staff", condominium_id: condominium.id)

      expect(result).to contain_exactly(admin.id, manager.id, doorman.id)
    end
  end

  describe "tipo: unidade" do
    it "includes occupant without owner nor responsible" do
      unit = create(:unit, building: building)
      user = create(:user)
      person = create(:person, condominium: condominium, user: user)
      create(:occupancy, unit: unit, person: person)

      result = service.call(tipo: "unidade", condominium_id: condominium.id, unit_id: unit.id)

      expect(result).to contain_exactly(user.id)
    end

    it "excludes Person without a User" do
      unit = create(:unit, building: building)
      person = create(:person, condominium: condominium, user: nil)
      create(:occupancy, unit: unit, person: person)

      result = service.call(tipo: "unidade", condominium_id: condominium.id, unit_id: unit.id)

      expect(result).to be_empty
    end
  end

  describe "tipo: torre" do
    it "includes moradores from all Unit of the Building" do
      unit_a = create(:unit, building: building)
      unit_b = create(:unit, building: building)
      user_a = create(:user)
      user_b = create(:user)
      create(:occupancy, unit: unit_a, person: create(:person, condominium: condominium, user: user_a))
      create(:occupancy, unit: unit_b, person: create(:person, condominium: condominium, user: user_b))

      result = service.call(tipo: "torre", condominium_id: condominium.id, building_id: building.id)

      expect(result).to contain_exactly(user_a.id, user_b.id)
    end

    it "deduplicates a Person occupying two Unit of the same Building" do
      unit_a = create(:unit, building: building)
      unit_b = create(:unit, building: building)
      user = create(:user)
      person = create(:person, condominium: condominium, user: user)
      create(:occupancy, unit: unit_a, person: person)
      create(:occupancy, unit: unit_b, person: person)

      result = service.call(tipo: "torre", condominium_id: condominium.id, building_id: building.id)

      expect(result).to contain_exactly(user.id)
    end
  end
end
