# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::MockPsp::SimulatePayment do
  subject(:service) { described_class.new }

  let(:fatura) { create(:fatura) }

  it "posts a webhook-shaped payload and returns the transaction_id on success" do
    allow(Net::HTTP).to receive(:post) do |uri, body, headers|
      expect(uri.path).to eq("/api/v1/billing/webhooks/payments")
      parsed = JSON.parse(body)
      expect(parsed["fatura_id"]).to eq(fatura.id)
      expect(headers["X-Webhook-Secret"]).to eq(ENV.fetch("BILLING_WEBHOOK_SECRET", "dev-webhook-secret"))
      Net::HTTPOK.new("1.1", "200", "OK")
    end

    result = service.call(fatura: fatura)

    expect(result).to be_success
    expect(result.value!).to match(/\AMOCK-\d+\z/)
  end

  it "fails when the webhook call does not succeed" do
    allow(Net::HTTP).to receive(:post).and_return(Net::HTTPInternalServerError.new("1.1", "500", "Error"))

    result = service.call(fatura: fatura)

    expect(result).to be_failure
    expect(result.failure).to eq(:webhook_call_failed)
  end
end
