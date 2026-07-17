# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  describe "POST /api/v1/invitations" do
    let(:admin) { create(:user, password: "secret123") }

    before { create(:membership, user: admin, condominium: condominium, role: "admin", status: "active") }

    it "creates an Invitation and returns the token (dev delivery channel)" do
      headers = auth_headers_for(admin)

      post "/api/v1/invitations",
           params:  { email: "novo@example.com", role: "resident" }.to_json,
           headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["email"]).to eq("novo@example.com")
      expect(body["invite_token"]).to be_present
    end

    it "forbids a non-admin from inviting" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      post "/api/v1/invitations",
           params:  { email: "novo@example.com", role: "resident" }.to_json,
           headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/invitations",
           params:  { email: "novo@example.com", role: "resident" }.to_json,
           headers: tenant_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/invitations/accept" do
    let(:invitation) { create(:invitation, condominium: condominium, email: "convidado@example.com") }

    it "activates the Membership" do
      post "/api/v1/invitations/accept",
           params:  { token: invitation.token, password: "password123", name: "Convidado" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "attributes", "role")).to eq("resident")
    end

    it "fails for an unknown token" do
      post "/api/v1/invitations/accept",
           params:  { token: "invalido", password: "password123", name: "Convidado" }.to_json,
           headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not require a tenant subdomain" do
      post "/api/v1/invitations/accept",
           params:  { token: invitation.token, password: "password123", name: "Convidado" }.to_json,
           headers: json_headers.merge("HOST" => "www.example.com")

      expect(response).to have_http_status(:ok)
    end
  end
end
