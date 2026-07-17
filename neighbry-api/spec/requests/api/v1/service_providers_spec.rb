# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ServiceProviders", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }
  let(:admin) { create(:user, password: "secret123") }

  before { create(:membership, user: admin, condominium: condominium, role: "admin", status: "active") }

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  def valid_cpf(seed = 1)
    base = format("%09d", 900_000_000 + seed)
    digits = base.chars.map(&:to_i)
    d1_sum = digits.each_with_index.sum { |d, i| d * (10 - i) }
    d1 = (d1_sum % 11) < 2 ? 0 : 11 - (d1_sum % 11)
    d2_sum = (digits + [d1]).each_with_index.sum { |d, i| d * (11 - i) }
    d2 = (d2_sum % 11) < 2 ? 0 : 11 - (d2_sum % 11)
    "#{base}#{d1}#{d2}"
  end

  describe "POST /api/v1/service_providers" do
    it "admin registers a service provider" do
      headers = auth_headers_for(admin)

      post "/api/v1/service_providers",
           params:  { name: "Prestador", cpf: valid_cpf }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body.dig("data", "attributes", "type")).to eq("service_provider")
    end

    it "forbids a plain user with no owner/responsible role" do
      plain_user = create(:user, password: "secret123")
      create(:membership, user: plain_user, condominium: condominium, role: "resident", status: "active")
      plain_person = create(:person, condominium: condominium, user: plain_user)
      create(:occupancy, unit: create(:unit, building: create(:building, condominium: condominium)), person: plain_person)
      headers = auth_headers_for(plain_user)

      post "/api/v1/service_providers",
           params:  { name: "Prestador", cpf: valid_cpf }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      post "/api/v1/service_providers",
           params:  { name: "Prestador", cpf: valid_cpf }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
