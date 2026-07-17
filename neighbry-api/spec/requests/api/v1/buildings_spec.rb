# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Buildings", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }
  let(:admin) { create(:user, password: "secret123") }

  before { create(:membership, user: admin, condominium: condominium, role: "admin", status: "active") }

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  describe "POST /api/v1/buildings" do
    it "admin creates a Building" do
      headers = auth_headers_for(admin)

      post "/api/v1/buildings", params: { name: "Bloco A" }.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "attributes", "name")).to eq("Bloco A")
    end

    it "forbids a non-admin (owner) from creating a Building" do
      owner = create(:user, password: "secret123")
      create(:membership, user: owner, condominium: condominium, role: "resident", status: "active")
      owner_person = create(:person, condominium: condominium, user: owner)
      create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: owner_person, owner: true)
      headers = auth_headers_for(owner)

      post "/api/v1/buildings", params: { name: "Bloco B" }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      post "/api/v1/buildings", params: { name: "Bloco A" }.to_json, headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
