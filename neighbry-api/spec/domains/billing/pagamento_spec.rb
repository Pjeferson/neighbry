# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::Pagamento, type: :model do
  subject(:pagamento) { build(:pagamento) }

  it { is_expected.to belong_to(:fatura) }
  it { is_expected.to validate_presence_of(:data) }

  it "is valid when valor matches the Fatura total" do
    fatura = create(:fatura)
    pagamento = build(:pagamento, fatura: fatura, valor: fatura.total)

    expect(pagamento).to be_valid
  end

  it "is invalid when valor differs from the Fatura total" do
    fatura = create(:fatura)
    pagamento = build(:pagamento, fatura: fatura, valor: fatura.total - 1)

    expect(pagamento).not_to be_valid
    expect(pagamento.errors[:valor]).to include("must equal the Fatura total")
  end

  it "rejects a second Pagamento for the same Fatura" do
    fatura = create(:fatura)
    create(:pagamento, fatura: fatura, valor: fatura.total)
    duplicate = build(:pagamento, fatura: fatura, valor: fatura.total)

    expect(duplicate).not_to be_valid
  end
end
