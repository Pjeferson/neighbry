# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registry::Person, type: :model do
  subject(:person) { build(:person) }

  it { is_expected.to belong_to(:condominium) }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to validate_presence_of(:name) }

  describe "type" do
    it "accepts resident and service_provider" do
      %w[resident service_provider].each do |type|
        person.type = type
        expect(person).to be_valid
      end
    end

    it "rejects a type outside the enum" do
      person.type = "admin"
      expect(person).not_to be_valid
    end
  end

  describe "cpf" do
    it "is valid with a well-formed CPF (valid checksum)" do
      expect(person).to be_valid
    end

    it "is invalid with the wrong number of digits" do
      person.cpf = "123"
      expect(person).not_to be_valid
    end

    it "is invalid with an incorrect checksum" do
      person.cpf = "11144477736" # último dígito errado (válido seria 35)
      expect(person).not_to be_valid
    end

    it "is invalid with all repeated digits" do
      person.cpf = "11111111111"
      expect(person).not_to be_valid
    end

    it "is unique within the same condominium" do
      person.save!
      duplicate = build(:person, cpf: person.cpf, condominium: person.condominium)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:cpf]).to include("has already been taken")
    end

    it "allows the same CPF in a different condominium" do
      person.save!
      other = build(:person, cpf: person.cpf, condominium: create(:condominium))

      expect(other).to be_valid
    end
  end
end
