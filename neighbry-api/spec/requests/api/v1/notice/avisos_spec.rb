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

  describe "PATCH /api/v1/notice/avisos/:id/confirmar" do
    it "destinatario confirms leitura" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin)
      create(:leitura, aviso: aviso, user: resident)
      headers = auth_headers_for(resident)

      patch "/api/v1/notice/avisos/#{aviso.id}/confirmar", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "attributes", "confirmado_em")).to be_present
    end

    it "rejects confirmation from a non-destinatario" do
      outsider = create(:user, password: "secret123")
      create(:membership, user: outsider, condominium: condominium, role: "resident", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin)
      headers = auth_headers_for(outsider)

      patch "/api/v1/notice/avisos/#{aviso.id}/confirmar", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects confirmation on a deactivated Aviso" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin, ativo: false)
      create(:leitura, aviso: aviso, user: resident)
      headers = auth_headers_for(resident)

      patch "/api/v1/notice/avisos/#{aviso.id}/confirmar", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/notice/avisos" do
    it "lists active Aviso where the current_user is a destinatario, with confirmado_em" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin)
      create(:leitura, aviso: aviso, user: resident)
      headers = auth_headers_for(resident)

      get "/api/v1/notice/avisos", headers: headers

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data.size).to eq(1)
      expect(data.first.dig("attributes", "confirmado_em")).to be_nil
    end

    it "excludes deactivated Aviso" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin, ativo: false)
      create(:leitura, aviso: aviso, user: resident)
      headers = auth_headers_for(resident)

      get "/api/v1/notice/avisos", headers: headers

      expect(response.parsed_body["data"]).to be_empty
    end

    it "excludes Aviso where the current_user is not a destinatario" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      create(:aviso, condominium: condominium, criado_por: admin)
      headers = auth_headers_for(resident)

      get "/api/v1/notice/avisos", headers: headers

      expect(response.parsed_body["data"]).to be_empty
    end
  end

  describe "GET /api/v1/notice/avisos/:id/painel" do
    it "admin sees the confirmation counter" do
      resident_a = create(:user, password: "secret123")
      resident_b = create(:user, password: "secret123")
      create(:membership, user: resident_a, condominium: condominium, role: "resident", status: "active")
      create(:membership, user: resident_b, condominium: condominium, role: "resident", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin)
      create(:leitura, aviso: aviso, user: resident_a, confirmado_em: Time.current)
      create(:leitura, aviso: aviso, user: resident_b)
      headers = auth_headers_for(admin)

      get "/api/v1/notice/avisos/#{aviso.id}/painel", headers: headers

      expect(response).to have_http_status(:ok)
      attrs = response.parsed_body.dig("data", "attributes")
      expect(attrs["total_destinatarios"]).to eq(2)
      expect(attrs["total_confirmados"]).to eq(1)
    end

    it "forbids staff non-admin from seeing the painel" do
      manager = create(:user, password: "secret123")
      create(:membership, user: manager, condominium: condominium, role: "manager", status: "active")
      aviso = create(:aviso, condominium: condominium, criado_por: admin)
      headers = auth_headers_for(manager)

      get "/api/v1/notice/avisos/#{aviso.id}/painel", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
