# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::ConfirmPayment do
  subject(:service) { described_class.new }

  let(:fatura) { create(:fatura) }

  it "confirms payment and moves the Fatura to pago" do
    result = service.call(fatura: fatura, metodo: "manual")

    expect(result).to be_success
    expect(result.value!.valor).to eq(fatura.total)
    expect(fatura.reload).to be_pago
  end

  it "publishes billing.fatura_paga" do
    events = []
    callback = ->(*, payload) { events << payload }

    ActiveSupport::Notifications.subscribed(callback, "billing.fatura_paga") do
      service.call(fatura: fatura, metodo: "manual")
    end

    expect(events).to contain_exactly(fatura_id: fatura.id)
  end

  it "persists a transaction_id when given (webhook path)" do
    result = service.call(fatura: fatura, metodo: "webhook", transaction_id: "MOCK-123")

    expect(result.value!.transaction_id).to eq("MOCK-123")
  end

  it "rejects a second confirmation of the same Fatura" do
    service.call(fatura: fatura, metodo: "manual")

    result = service.call(fatura: fatura, metodo: "manual")

    expect(result).to be_failure
    expect(result.failure).to eq(:already_paid)
    expect(Billing::Pagamento.where(fatura: fatura).count).to eq(1)
  end
end
