# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation::Booking, type: :model do
  subject(:booking) { build(:booking) }

  around do |example|
    travel_to(Date.new(2026, 7, 31)) { example.run }
  end

  def occupancy_in(condominium, **attrs)
    unit = create(:unit, building: create(:building, condominium: condominium))
    create(:occupancy, unit: unit, **attrs)
  end

  it { is_expected.to belong_to(:common_area) }
  it { is_expected.to belong_to(:occupancy) }

  it "inherits condominium_id from the common_area" do
    booking.valid?
    expect(booking.condominium_id).to eq(booking.common_area.condominium_id)
  end

  it "inherits unit_id from the occupancy" do
    booking.valid?
    expect(booking.unit_id).to eq(booking.occupancy.unit_id)
  end

  it "truncates competencia to the first day of the month" do
    booking.data = Date.new(2026, 8, 15)
    booking.valid?

    expect(booking.competencia).to eq(Date.new(2026, 8, 1))
  end

  describe "janela de data" do
    it "rejects a past date" do
      booking.data = Date.current - 1.day
      expect(booking).not_to be_valid
    end

    it "accepts today" do
      booking.data = Date.current
      expect(booking).to be_valid
    end

    it "accepts up to 30 days ahead" do
      booking.data = Date.current + 30.days
      expect(booking).to be_valid
    end

    it "rejects more than 30 days ahead" do
      booking.data = Date.current + 31.days
      expect(booking).not_to be_valid
    end
  end

  describe "papel da occupancy" do
    it "accepts an active owner" do
      booking.occupancy = occupancy_in(booking.common_area.condominium, owner: true)
      expect(booking).to be_valid
    end

    it "accepts an active responsible" do
      booking.occupancy = occupancy_in(booking.common_area.condominium, responsible: true)
      expect(booking).to be_valid
    end

    it "rejects an occupant that is neither owner nor responsible" do
      booking.occupancy = occupancy_in(booking.common_area.condominium, owner: false, responsible: false)
      expect(booking).not_to be_valid
    end

    it "rejects an inactive (ended) occupancy" do
      booking.occupancy = occupancy_in(booking.common_area.condominium, owner: true, end_date: Date.current)
      expect(booking).not_to be_valid
    end
  end

  it "rejects a CommonArea that is inactive" do
    booking.common_area = create(:common_area, ativo: false)
    expect(booking).not_to be_valid
  end

  describe "conflito de turno" do
    it "rejects a second active Booking for the same common_area, data and turno" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      duplicate = build(:booking, common_area: existing.common_area,
        occupancy: occupancy_in(existing.common_area.condominium, owner: true),
        data: existing.data, turno: "manha")

      expect(duplicate).not_to be_valid
    end

    it "allows a different turno on the same day and space" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      other = build(:booking, common_area: existing.common_area,
        occupancy: occupancy_in(existing.common_area.condominium, owner: true),
        data: existing.data, turno: "tarde")

      expect(other).to be_valid
    end

    it "allows a new Booking once the conflicting one is cancelled" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      existing.cancel!
      duplicate = build(:booking, common_area: existing.common_area,
        occupancy: occupancy_in(existing.common_area.condominium, owner: true),
        data: existing.data, turno: "manha")

      expect(duplicate).to be_valid
    end

    it "enforces uniqueness at the database level even bypassing the app-level validation" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      duplicate = build(:booking, common_area: existing.common_area,
        occupancy: occupancy_in(existing.common_area.condominium, owner: true),
        data: existing.data, turno: "manha")
      allow(duplicate).to receive(:common_area_has_no_active_booking_for_turno)

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "limite mensal por unidade" do
    it "rejects a second active Booking for the same unit and common_area in the same month" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      duplicate = build(:booking, common_area: existing.common_area,
        occupancy: create(:occupancy, unit: existing.unit, responsible: true),
        data: Date.current + 6.days, turno: "tarde")

      expect(duplicate).not_to be_valid
    end

    it "allows a Booking for a different CommonArea in the same month" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      other_common_area = create(:common_area, condominium: existing.common_area.condominium)
      other = build(:booking, common_area: other_common_area,
        occupancy: create(:occupancy, unit: existing.unit, responsible: true),
        data: Date.current + 6.days, turno: "manha")

      expect(other).to be_valid
    end

    it "allows a Booking for the same CommonArea in a different month" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      other = build(:booking, common_area: existing.common_area,
        occupancy: create(:occupancy, unit: existing.unit, responsible: true),
        data: Date.current, turno: "manha")

      expect(existing.data.beginning_of_month).not_to eq(other.data.beginning_of_month)
      expect(other).to be_valid
    end

    it "allows a new Booking once the conflicting one is cancelled" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      existing.cancel!
      duplicate = build(:booking, common_area: existing.common_area,
        occupancy: create(:occupancy, unit: existing.unit, responsible: true),
        data: Date.current + 6.days, turno: "tarde")

      expect(duplicate).to be_valid
    end

    it "enforces uniqueness at the database level even bypassing the app-level validation" do
      existing = create(:booking, data: Date.current + 5.days, turno: "manha")
      duplicate = build(:booking, common_area: existing.common_area,
        occupancy: create(:occupancy, unit: existing.unit, responsible: true),
        data: Date.current + 6.days, turno: "tarde")
      allow(duplicate).to receive(:unit_has_no_active_booking_for_common_area_in_competencia)

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#active?" do
    it "is true when cancelada_em is nil" do
      expect(build(:booking)).to be_active
    end

    it "is false when cancelada_em is present" do
      booking.cancelada_em = Time.current
      expect(booking).not_to be_active
    end
  end

  describe "#cancel!" do
    it "sets cancelada_em without deleting the record" do
      created = create(:booking)
      created.cancel!

      expect(created.reload.cancelada_em).to be_present
      expect(Reservation::Booking.exists?(created.id)).to be(true)
    end
  end
end
