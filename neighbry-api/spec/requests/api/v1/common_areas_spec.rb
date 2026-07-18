# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CommonAreas", type: :request do
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

  describe "POST /api/v1/common_areas" do
    it "admin creates a CommonArea" do
      headers = auth_headers_for(admin)

      post "/api/v1/common_areas", params: { nome: "Salão de Festas", capacidade: 50 }.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "attributes", "nome")).to eq("Salão de Festas")
    end

    it "forbids a non-admin from creating a CommonArea" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      post "/api/v1/common_areas", params: { nome: "Salão de Festas", capacidade: 50 }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/common_areas/:id" do
    it "admin edits an existing CommonArea" do
      common_area = create(:common_area, condominium: condominium)
      headers = auth_headers_for(admin)

      patch "/api/v1/common_areas/#{common_area.id}", params: { nome: "Novo nome", ativo: false }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      attrs = response.parsed_body.dig("data", "attributes")
      expect(attrs["nome"]).to eq("Novo nome")
      expect(attrs["ativo"]).to be(false)
    end

    it "forbids a non-admin from editing" do
      common_area = create(:common_area, condominium: condominium)
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      patch "/api/v1/common_areas/#{common_area.id}", params: { nome: "Novo nome" }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
