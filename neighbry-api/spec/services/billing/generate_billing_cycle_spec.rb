# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::GenerateBillingCycle do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  context "when the condominium has a billing setting" do
    before { create(:condominium_billing_setting, condominium: condominium) }

    it "creates a CicloCobranca for the current competencia" do
      result = service.call(condominium: condominium)

      expect(result).to be_success
      expect(result.value!.competencia).to eq(Date.current.beginning_of_month)
      expect(result.value!).to be_gerando
    end

    it "is idempotent — a second call returns the same cycle" do
      first = service.call(condominium: condominium).value!
      second = service.call(condominium: condominium).value!

      expect(second.id).to eq(first.id)
      expect(Billing::CicloCobranca.where(condominium: condominium).count).to eq(1)
    end
  end

  context "when the condominium has no billing setting" do
    it "fails without creating a cycle" do
      result = service.call(condominium: condominium)

      expect(result).to be_failure
      expect(result.failure).to eq(:no_billing_setting)
      expect(Billing::CicloCobranca.where(condominium: condominium).count).to eq(0)
    end
  end
end
