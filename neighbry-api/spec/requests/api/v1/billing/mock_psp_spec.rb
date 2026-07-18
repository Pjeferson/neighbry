# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing::MockPsp", type: :request do
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

  describe "POST /api/v1/billing/mock_psp/simulate" do
    it "admin triggers a simulated payment via a real HTTP call to the webhook endpoint" do
      fatura = create(:fatura, unit: unit, condominium: condominium)
      headers = auth_headers_for(admin)

      allow_any_instance_of(Net::HTTP).to receive(:request) do |_http, request|
        expect(request.path).to eq("/api/v1/billing/webhooks/payments")
        expect(JSON.parse(request.body)["fatura_id"]).to eq(fatura.id)
        expect(request["X-Webhook-Secret"]).to be_present
        Net::HTTPOK.new("1.1", "200", "OK")
      end

      post "/api/v1/billing/mock_psp/simulate", params: { fatura_id: fatura.id }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["transaction_id"]).to match(/\AMOCK-\d+\z/)
    end

    it "forbids a non-admin from simulating a payment" do
      fatura = create(:fatura, unit: unit, condominium: condominium)
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(plain_user)

      post "/api/v1/billing/mock_psp/simulate", params: { fatura_id: fatura.id }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
