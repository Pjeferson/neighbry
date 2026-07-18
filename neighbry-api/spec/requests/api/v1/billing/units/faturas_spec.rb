# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing::Units::Faturas", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }
  let(:admin) { create(:user, password: "secret123") }

  before do
    create(:membership, user: admin, condominium: condominium, role: "admin", status: "active")
    create(:fatura, unit: unit, condominium: condominium)
  end

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  def resident_with_occupancy(owner: false, responsible: false)
    user = create(:user, password: "secret123")
    create(:membership, user: user, condominium: condominium, role: "resident", status: "active")
    person = create(:person, condominium: condominium, user: user)
    create(:occupancy, unit: unit, person: person, owner: owner, responsible: responsible)
    user
  end

  describe "GET /api/v1/billing/units/:unit_id/faturas" do
    it "admin sees the Unit's Faturas" do
      headers = auth_headers_for(admin)

      get "/api/v1/billing/units/#{unit.id}/faturas", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(1)
    end

    it "owner sees the Unit's Faturas" do
      owner = resident_with_occupancy(owner: true)
      headers = auth_headers_for(owner)

      get "/api/v1/billing/units/#{unit.id}/faturas", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(1)
    end

    it "plain resident (no owner/responsible) sees the Unit's Faturas" do
      resident = resident_with_occupancy
      headers = auth_headers_for(resident)

      get "/api/v1/billing/units/#{unit.id}/faturas", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(1)
    end

    it "forbids a resident of a different Unit" do
      other_unit = create(:unit, building: building)
      outsider = create(:user, password: "secret123")
      create(:membership, user: outsider, condominium: condominium, role: "resident", status: "active")
      person = create(:person, condominium: condominium, user: outsider)
      create(:occupancy, unit: other_unit, person: person)
      headers = auth_headers_for(outsider)

      get "/api/v1/billing/units/#{unit.id}/faturas", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids a user with no Occupancy anywhere" do
      stranger = create(:user, password: "secret123")
      create(:membership, user: stranger, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(stranger)

      get "/api/v1/billing/units/#{unit.id}/faturas", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
