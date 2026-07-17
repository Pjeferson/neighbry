# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memberships", type: :request do
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

  describe "PATCH /api/v1/memberships/:id/revoke" do
    it "revokes an active Membership as admin" do
      target_user = create(:user)
      membership = create(:membership, user: target_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(admin)

      patch "/api/v1/memberships/#{membership.id}/revoke", headers: headers

      expect(response).to have_http_status(:ok)
      expect(membership.reload.status).to eq("revoked")
    end

    it "forbids a non-admin from revoking" do
      resident = create(:user, password: "secret123")
      create(:membership, user: resident, condominium: condominium, role: "resident", status: "active")
      target_user = create(:user)
      membership = create(:membership, user: target_user, condominium: condominium, role: "resident", status: "active")
      headers = auth_headers_for(resident)

      patch "/api/v1/memberships/#{membership.id}/revoke", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(membership.reload.status).to eq("active")
    end
  end
end
