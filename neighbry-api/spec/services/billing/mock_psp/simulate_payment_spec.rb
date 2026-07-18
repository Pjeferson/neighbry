# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::MockPsp::SimulatePayment do
  subject(:service) { described_class.new }

  let(:fatura) { create(:fatura) }

  it "posts a webhook-shaped payload and returns the transaction_id on success" do
    allow_any_instance_of(Net::HTTP).to receive(:request) do |_http, request|
      expect(request.path).to eq("/api/v1/billing/webhooks/payments")
      parsed = JSON.parse(request.body)
      expect(parsed["fatura_id"]).to eq(fatura.id)
      expect(request["X-Webhook-Secret"]).to eq(ENV.fetch("BILLING_WEBHOOK_SECRET", "dev-webhook-secret"))
      Net::HTTPOK.new("1.1", "200", "OK")
    end

    result = service.call(fatura: fatura)

    expect(result).to be_success
    expect(result.value!).to match(/\AMOCK-\d+\z/)
  end

  it "fails when the webhook call does not succeed" do
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(Net::HTTPInternalServerError.new("1.1", "500", "Error"))

    result = service.call(fatura: fatura)

    expect(result).to be_failure
    expect(result.failure).to eq(:webhook_call_failed)
  end

  it "fails gracefully when the request times out (self-request quirk, ConfirmPayment stays idempotent)" do
    allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::ReadTimeout)

    result = service.call(fatura: fatura)

    expect(result).to be_failure
    expect(result.failure).to eq(:webhook_call_timed_out)
  end
end
