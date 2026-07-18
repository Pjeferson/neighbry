# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::CondominiumBillingSetting, type: :model do
  subject(:setting) { build(:condominium_billing_setting) }

  it { is_expected.to belong_to(:condominium) }

  it "is invalid without a second setting for the same condominium" do
    condominium = create(:condominium)
    create(:condominium_billing_setting, condominium: condominium)
    duplicate = build(:condominium_billing_setting, condominium: condominium)

    expect(duplicate).not_to be_valid
  end

  it "rejects dia_cobranca outside 0..15" do
    setting.dia_cobranca = 16
    expect(setting).not_to be_valid
  end

  it "accepts dia_cobranca at the boundaries" do
    expect(build(:condominium_billing_setting, dia_cobranca: 0)).to be_valid
    expect(build(:condominium_billing_setting, dia_cobranca: 15)).to be_valid
  end

  it "rejects dias_para_vencimento not greater than zero" do
    setting.dias_para_vencimento = 0
    expect(setting).not_to be_valid
  end
end
