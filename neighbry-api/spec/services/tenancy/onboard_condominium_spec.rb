# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tenancy::OnboardCondominium do
  subject(:service) { described_class.new }

  let(:params) do
    {
      condominium_name: "Acme",
      condominium_slug: "acme",
      admin_email: "admin@example.com",
      admin_password: "password123",
      admin_name: "Admin"
    }
  end

  it "creates Condominium, User and an admin Membership atomically" do
    result = service.call(**params)

    expect(result).to be_success
    membership = result.value!
    expect(membership).to be_admin
    expect(membership).to be_active
    expect(membership.condominium.slug).to eq("acme")
    expect(membership.user.email).to eq("admin@example.com")
  end

  it "leaves no partial records when the slug is already taken" do
    create(:condominium, slug: "acme")
    result = nil

    expect do
      result = service.call(**params)
    end.not_to change(User, :count)

    expect(result).to be_failure
    expect(Tenancy::Membership.count).to eq(0)
  end

  it "leaves no partial records when the admin email is already taken" do
    create(:user, email: "admin@example.com")
    result = nil

    expect do
      result = service.call(**params)
    end.not_to change(Tenancy::Condominium, :count)

    expect(result).to be_failure
    expect(Tenancy::Membership.count).to eq(0)
  end
end
