# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing::Webhooks::Payments", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }
  let(:fatura) { create(:fatura, unit: unit, condominium: condominium) }

  def webhook_secret
    ENV.fetch("BILLING_WEBHOOK_SECRET", "dev-webhook-secret")
  end

  describe "POST /api/v1/billing/webhooks/payments" do
    it "confirms payment when the secret is correct" do
      post "/api/v1/billing/webhooks/payments",
           params:  { fatura_id: fatura.id, transaction_id: "MOCK-123" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "X-Webhook-Secret" => webhook_secret }

      expect(response).to have_http_status(:ok)
      expect(fatura.reload).to be_pago
      expect(fatura.pagamento.transaction_id).to eq("MOCK-123")
    end

    it "rejects the confirmation when the secret is missing or wrong" do
      post "/api/v1/billing/webhooks/payments",
           params:  { fatura_id: fatura.id, transaction_id: "MOCK-123" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "X-Webhook-Secret" => "wrong-secret" }

      expect(response).to have_http_status(:unauthorized)
      expect(fatura.reload).to be_pendente
    end

    it "does not require a user session token" do
      post "/api/v1/billing/webhooks/payments",
           params:  { fatura_id: fatura.id, transaction_id: "MOCK-123" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "X-Webhook-Secret" => webhook_secret }

      expect(response).to have_http_status(:ok)
    end
  end
end
