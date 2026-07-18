# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SetBillingDay do
  subject(:service) { described_class.new }

  let(:condominium) { create(:condominium) }

  def admin_user
    user = create(:user)
    create(:membership, user: user, condominium: condominium, role: "admin", status: "active")
    user
  end

  it "creates the setting when none exists yet" do
    result = service.call(actor: admin_user, condominium: condominium, dia_cobranca: 7, dias_para_vencimento: 15)

    expect(result).to be_success
    expect(result.value!.dia_cobranca).to eq(7)
  end

  it "updates an existing setting instead of creating a second one" do
    create(:condominium_billing_setting, condominium: condominium, dia_cobranca: 5, dias_para_vencimento: 10)

    result = service.call(actor: admin_user, condominium: condominium, dia_cobranca: 12, dias_para_vencimento: 20)

    expect(result).to be_success
    expect(Billing::CondominiumBillingSetting.where(condominium_id: condominium.id).count).to eq(1)
    expect(result.value!.dia_cobranca).to eq(12)
  end

  it "forbids a non-admin from setting the billing day" do
    plain_user = create(:user)

    result = service.call(actor: plain_user, condominium: condominium, dia_cobranca: 7, dias_para_vencimento: 15)

    expect(result).to be_failure
    expect(result.failure).to eq(:unauthorized)
  end
end
