# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Occupancies", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }
  let(:admin) { create(:user, password: "secret123") }

  before { create(:membership, user: admin, condominium: condominium, role: "admin", status: "active") }

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

  describe "POST /api/v1/units/:unit_id/occupancies" do
    it "registers an owner as admin" do
      headers = auth_headers_for(admin)

      post "/api/v1/units/#{unit.id}/occupancies",
           params:  { name: "Dono", cpf: valid_cpf, owner: true }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body.dig("data", "attributes", "owner")).to be(true)
    end

    it "requires authentication" do
      post "/api/v1/units/#{unit.id}/occupancies",
           params:  { name: "Dono", cpf: valid_cpf, owner: true }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "forbids a plain user from registering someone" do
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      plain_person = create(:person, condominium: condominium, user: plain_user)
      create(:occupancy, unit: unit, person: plain_person)
      headers = auth_headers_for(plain_user)

      post "/api/v1/units/#{unit.id}/occupancies",
           params:  { name: "Outro", cpf: valid_cpf(2), owner: true }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 for a unit belonging to a different condominium" do
      other_unit = create(:unit, building: create(:building, condominium: create(:condominium)))
      headers = auth_headers_for(admin)

      post "/api/v1/units/#{other_unit.id}/occupancies",
           params:  { name: "Dono", cpf: valid_cpf, owner: true }.to_json,
           headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/occupancies/:id/close" do
    it "admin closes an owner Occupancy" do
      occupancy = create(:occupancy, unit: unit, owner: true)
      headers = auth_headers_for(admin)

      patch "/api/v1/occupancies/#{occupancy.id}/close", headers: headers

      expect(response).to have_http_status(:ok)
      expect(occupancy.reload).not_to be_active
    end

    it "forbids the owner from closing their own Occupancy" do
      owner = create(:user, password: "secret123")
      create(:membership, user: owner, condominium: condominium, role: "resident", status: "active")
      owner_person = create(:person, condominium: condominium, user: owner)
      occupancy = create(:occupancy, unit: unit, person: owner_person, owner: true)
      headers = auth_headers_for(owner)

      patch "/api/v1/occupancies/#{occupancy.id}/close", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(occupancy.reload).to be_active
    end
  end
end
