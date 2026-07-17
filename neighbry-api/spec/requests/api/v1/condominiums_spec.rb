# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Condominiums", type: :request do
  describe "POST /api/v1/condominiums" do
    let(:valid_params) do
      {
        condominium_name: "Acme",
        condominium_slug: "acme",
        admin_email: "admin@example.com",
        admin_password: "password123",
        admin_name: "Admin"
      }
    end

    it "creates Condominium, User and admin Membership atomically" do
      expect do
        post "/api/v1/condominiums", params: valid_params.to_json, headers: json_headers
      end.to change(Tenancy::Condominium, :count).by(1)
        .and change(User, :count).by(1)
        .and change(Tenancy::Membership, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["condominium"]["slug"]).to eq("acme")
      expect(body["admin"]["email"]).to eq("admin@example.com")
    end

    it "does not require a tenant subdomain" do
      post "/api/v1/condominiums", params: valid_params.to_json, headers: json_headers.merge("HOST" => "www.example.com")

      expect(response).to have_http_status(:created)
    end

    it "leaves no partial records when the slug is already taken" do
      create(:condominium, slug: "acme")

      expect do
        post "/api/v1/condominiums", params: valid_params.to_json, headers: json_headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(Tenancy::Membership.count).to eq(0)
    end
  end
end
