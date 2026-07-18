# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notice::Avisos", type: :request do
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

  describe "POST /api/v1/notice/avisos" do
    it "admin creates an Aviso" do
      headers = auth_headers_for(admin)

      post "/api/v1/notice/avisos",
           params:  { titulo: "Assembleia", corpo: "Dia 10 às 19h", tipo: "todos" }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "attributes", "titulo")).to eq("Assembleia")
    end

    it "forbids a non-admin from creating an Aviso" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      post "/api/v1/notice/avisos",
           params:  { titulo: "Assembleia", corpo: "Dia 10", tipo: "todos" }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/notice/avisos/:id/deactivate" do
    it "admin deactivates an Aviso" do
      headers = auth_headers_for(admin)
      aviso = create(:aviso, condominium: condominium, criado_por: admin)

      patch "/api/v1/notice/avisos/#{aviso.id}/deactivate", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "attributes", "ativo")).to be(false)
    end

    it "forbids a non-admin from deactivating an Aviso" do
      aviso = create(:aviso, condominium: condominium, criado_por: admin)
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      patch "/api/v1/notice/avisos/#{aviso.id}/deactivate", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
