# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notice::Leitura, type: :model do
  subject(:leitura) { build(:leitura) }

  it { is_expected.to belong_to(:aviso) }
  it { is_expected.to belong_to(:user) }

  it "rejects a duplicate (aviso_id, user_id) at the database level" do
    created = create(:leitura)
    duplicate = build(:leitura, aviso: created.aviso, user: created.user)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe "#confirmado?" do
    it "is false when confirmado_em is nil" do
      expect(leitura).not_to be_confirmado
    end

    it "is true when confirmado_em is present" do
      leitura.confirmado_em = Time.current
      expect(leitura).to be_confirmado
    end
  end
end
