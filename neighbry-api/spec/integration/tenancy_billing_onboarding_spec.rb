# frozen_string_literal: true

require "rails_helper"

# Prova de ponta a ponta da integração Tenancy -> Billing: ao onboardar um
# Condominium, Tenancy publica tenancy.condominium_onboarded (Domain Event),
# e Billing reage criando uma configuração de cobrança padrão — sem nenhuma
# chamada direta de código entre os dois módulos (ver design.md Decisão
# "BillingSetting criado automaticamente ao onboardar um Condominium").
RSpec.describe "Tenancy -> Billing onboarding" do
  it "creates a default CondominiumBillingSetting when a Condominium is onboarded" do
    result = Tenancy::OnboardCondominium.new.call(
      condominium_name: "Acme",
      condominium_slug: "acme-onboarding-spec",
      admin_email: "admin@acme-onboarding-spec.example.com",
      admin_password: "password123",
      admin_name: "Admin"
    )
    expect(result).to be_success

    condominium = result.value!.condominium
    setting = Billing::CondominiumBillingSetting.find_by(condominium_id: condominium.id)

    expect(setting).to be_present
    expect(setting.dia_cobranca).to eq(Billing::CreateDefaultBillingSetting::DEFAULT_DIA_COBRANCA)
  end
end
