# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing::Settings", type: :request do
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

  describe "PUT /api/v1/billing/settings" do
    it "admin sets the billing day and due days" do
      headers = auth_headers_for(admin)

      put "/api/v1/billing/settings", params: { dia_cobranca: 10, dias_para_vencimento: 15 }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "attributes", "dia_cobranca")).to eq(10)
    end

    it "forbids a non-admin from updating the setting" do
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(plain_user)

      put "/api/v1/billing/settings", params: { dia_cobranca: 10, dias_para_vencimento: 15 }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
