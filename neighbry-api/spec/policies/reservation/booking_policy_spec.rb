# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation::BookingPolicy do
  let(:condominium) { create(:condominium) }
  let(:unit) { create(:unit, building: create(:building, condominium: condominium)) }

  describe "#create?" do
    subject(:policy) { described_class.new(user, unit) }

    context "when the user is the active owner of the unit" do
      let(:user) { create(:user) }
      let(:person) { create(:person, condominium: condominium, user: user) }

      before { create(:occupancy, unit: unit, person: person, owner: true) }

      it { is_expected.to be_create }
    end

    context "when the user is the active responsible of the unit" do
      let(:user) { create(:user) }
      let(:person) { create(:person, condominium: condominium, user: user) }

      before { create(:occupancy, unit: unit, person: person, responsible: true) }

      it { is_expected.to be_create }
    end

    context "when the user is a plain occupant (neither owner nor responsible)" do
      let(:user) { create(:user) }
      let(:person) { create(:person, condominium: condominium, user: user) }

      before { create(:occupancy, unit: unit, person: person, owner: false, responsible: false) }

      it { is_expected.not_to be_create }
    end

    context "when the owner's Occupancy has already ended" do
      let(:user) { create(:user) }
      let(:person) { create(:person, condominium: condominium, user: user) }

      before { create(:occupancy, unit: unit, person: person, owner: true, end_date: Date.current) }

      it { is_expected.not_to be_create }
    end

    context "when the user has no role in this unit" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_create }
    end

    context "when the user is admin but not owner/responsible" do
      let(:user) { create(:user) }

      before { create(:membership, user: user, condominium: condominium, role: "admin", status: "active") }

      it "still forbids — admin is not automatically an owner/responsible" do
        expect(policy).not_to be_create
      end
    end

    context "when there is no user" do
      let(:user) { nil }

      it { is_expected.not_to be_create }
    end
  end

  describe "#list?" do
    subject(:policy) { described_class.new(user, condominium) }

    context "when the user has an active Membership" do
      let(:user) { create(:user) }

      before { create(:membership, user: user, condominium: condominium, role: "resident", status: "active") }

      it { is_expected.to be_list }
    end

    context "when the user has no Membership in the condominium" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_list }
    end

    context "when there is no user" do
      let(:user) { nil }

      it { is_expected.not_to be_list }
    end
  end

  describe "#cancel?" do
    subject(:policy) { described_class.new(user, booking) }

    let(:booking) { create(:booking) }

    context "when the user is the author of the Booking (via Occupancy)" do
      let(:user) { create(:user) }

      before { booking.occupancy.person.update!(user: user) }

      it { is_expected.to be_cancel }
    end

    context "when the user is a different resident" do
      let(:user) { create(:user) }

      it { is_expected.not_to be_cancel }
    end

    context "when there is no user" do
      let(:user) { nil }

      it { is_expected.not_to be_cancel }
    end
  end
end
