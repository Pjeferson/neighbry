# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Units", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:building) { create(:building, condominium: condominium) }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }
  let(:admin) { create(:user, password: "secret123") }

  before { create(:membership, user: admin, condominium: condominium, role: "admin", status: "active") }

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  describe "POST /api/v1/buildings/:building_id/units" do
    it "admin creates a Unit in a Building of their own condominium" do
      headers = auth_headers_for(admin)

      post "/api/v1/buildings/#{building.id}/units", params: { identification: "101" }.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "attributes", "identification")).to eq("101")
    end

    it "returns 404 for a Building belonging to a different condominium" do
      other_building = create(:building, condominium: create(:condominium))
      headers = auth_headers_for(admin)

      post "/api/v1/buildings/#{other_building.id}/units", params: { identification: "101" }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "forbids a non-admin from creating a Unit" do
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(plain_user)

      post "/api/v1/buildings/#{building.id}/units", params: { identification: "101" }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
