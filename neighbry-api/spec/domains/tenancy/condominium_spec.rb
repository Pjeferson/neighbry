# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::Condominium, type: :model do
  subject(:condominium) { build(:condominium) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_uniqueness_of(:slug) }

  describe "slug format" do
    it "rejects uppercase characters" do
      condominium.slug = "Acme"
      expect(condominium).not_to be_valid
    end

    it "rejects underscores" do
      condominium.slug = "acme_condo"
      expect(condominium).not_to be_valid
    end

    it "accepts lowercase letters, numbers and hyphens" do
      condominium.slug = "acme-condo-2"
      expect(condominium).to be_valid
    end
  end
end
