# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:user) { create(:user, password: "secret123") }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }

  describe "POST /api/v1/auth/sign_in" do
    it "returns JWT on valid credentials with an active Membership in the tenant" do
      create(:membership, user: user, condominium: condominium, status: "active")

      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "secret123" } }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to match(/\ABearer .+\z/)
    end

    it "includes the Membership role in the response body" do
      create(:membership, user: user, condominium: condominium, role: "manager", status: "active")

      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "secret123" } }.to_json,
           headers: tenant_headers

      expect(response.parsed_body["role"]).to eq("manager")
    end

    it "returns 401 on wrong password" do
      create(:membership, user: user, condominium: condominium, status: "active")

      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "wrong" } }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for unknown email" do
      condominium

      post "/api/v1/auth/sign_in",
           params:  { user: { email: "no@one.com", password: "secret123" } }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the User has no Membership in the tenant" do
      condominium

      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "secret123" } }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("no_active_membership_for_tenant")
      expect(response.headers["Authorization"]).to be_nil
    end

    it "returns 401 when the Membership in the tenant is revoked" do
      create(:membership, user: user, condominium: condominium, status: "revoked")

      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "secret123" } }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("no_active_membership_for_tenant")
      expect(response.headers["Authorization"]).to be_nil
    end

    it "returns 404 when the subdomain matches no Condominium" do
      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "secret123" } }.to_json,
           headers: json_headers.merge("HOST" => "unknown.example.com")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "returns 200 using the token obtained from sign_in, without needing a tenant subdomain" do
      create(:membership, user: user, condominium: condominium, status: "active")

      post "/api/v1/auth/sign_in",
           params:  { user: { email: user.email, password: "secret123" } }.to_json,
           headers: tenant_headers

      token = response.headers["Authorization"]
      delete "/api/v1/auth/sign_out", headers: { "Authorization" => token }
      expect(response).to have_http_status(:ok)
    end
  end
end
