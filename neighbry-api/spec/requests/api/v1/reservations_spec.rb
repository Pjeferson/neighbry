# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reservations", type: :request do
  around do |example|
    travel_to(Date.new(2026, 7, 31)) { example.run }
  end

  let(:condominium) { create(:condominium, slug: "acme") }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }
  let(:common_area) { create(:common_area, condominium: condominium) }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  def valid_cpf(seed = 1)
    base = format("%09d", 800_000_000 + seed)
    digits = base.chars.map(&:to_i)
    d1_sum = digits.each_with_index.sum { |d, i| d * (10 - i) }
    d1 = (d1_sum % 11) < 2 ? 0 : 11 - (d1_sum % 11)
    d2_sum = (digits + [d1]).each_with_index.sum { |d, i| d * (11 - i) }
    d2 = (d2_sum % 11) < 2 ? 0 : 11 - (d2_sum % 11)
    "#{base}#{d1}#{d2}"
  end

  def owner_user(seed = 1)
    user = create(:user, password: "secret123")
    create(:membership, user: user, condominium: condominium, role: "resident", status: "active")
    person = create(:person, condominium: condominium, user: user, cpf: valid_cpf(seed))
    create(:occupancy, unit: unit, person: person, owner: true)
    user
  end

  describe "POST /api/v1/reservations" do
    it "the unit's owner creates a Booking" do
      headers = auth_headers_for(owner_user)

      post "/api/v1/reservations",
           params:  { unit_id: unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "attributes", "turno")).to eq("manha")
    end

    it "forbids a resident with no role in the unit" do
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(plain_user)

      post "/api/v1/reservations",
           params:  { unit_id: unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      post "/api/v1/reservations",
           params:  { unit_id: unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a second reservation for the same space, date and turno" do
      headers = auth_headers_for(owner_user)
      post "/api/v1/reservations",
           params:  { unit_id: unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: headers

      other_unit = create(:unit, building: building)
      other_owner = create(:user, password: "secret123")
      create(:membership, user: other_owner, condominium: condominium, role: "resident", status: "active")
      other_person = create(:person, condominium: condominium, user: other_owner, cpf: valid_cpf(2))
      create(:occupancy, unit: other_unit, person: other_person, owner: true)
      other_headers = auth_headers_for(other_owner)

      post "/api/v1/reservations",
           params:  { unit_id: other_unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: other_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/reservations/:id" do
    it "the author cancels their own Booking" do
      user = owner_user
      headers = auth_headers_for(user)
      post "/api/v1/reservations",
           params:  { unit_id: unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: headers
      booking_id = response.parsed_body.dig("data", "id")

      delete "/api/v1/reservations/#{booking_id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(Reservation::Booking.find(booking_id)).not_to be_active
    end

    it "forbids a different resident from cancelling" do
      user = owner_user
      headers = auth_headers_for(user)
      post "/api/v1/reservations",
           params:  { unit_id: unit.id, common_area_id: common_area.id, data: (Date.current + 1.day).iso8601, turno: "manha" }.to_json,
           headers: headers
      booking_id = response.parsed_body.dig("data", "id")

      other_resident = create(:user, password: "secret123")
      create(:membership, user: other_resident, condominium: condominium, role: "resident", status: "active")
      other_headers = auth_headers_for(other_resident)

      delete "/api/v1/reservations/#{booking_id}", headers: other_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(Reservation::Booking.find(booking_id)).to be_active
    end
  end

  describe "GET /api/v1/reservations" do
    it "any active Membership sees the listing" do
      create(:booking, common_area: common_area, occupancy: create(:occupancy, unit: unit, owner: true), data: Date.current + 1.day)
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      get "/api/v1/reservations", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(1)
    end

    it "forbids a User whose Membership was revoked after authenticating" do
      resident = create(:user, password: "secret123")
      membership = create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)
      membership.update!(status: "revoked")

      get "/api/v1/reservations", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
