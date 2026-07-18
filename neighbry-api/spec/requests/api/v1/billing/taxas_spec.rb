# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing::Taxas", type: :request do
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

  describe "POST /api/v1/billing/taxas" do
    it "admin creates a Taxa" do
      headers = auth_headers_for(admin)

      post "/api/v1/billing/taxas",
           params:  { valor: 150.0, descricao: "Taxa condominial", data_inicio: Date.current.to_s }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "attributes", "descricao")).to eq("Taxa condominial")
    end

    it "forbids a non-admin from creating a Taxa" do
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(plain_user)

      post "/api/v1/billing/taxas",
           params:  { valor: 150.0, descricao: "Taxa condominial", data_inicio: Date.current.to_s }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      post "/api/v1/billing/taxas",
           params:  { valor: 150.0, descricao: "Taxa condominial", data_inicio: Date.current.to_s }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
