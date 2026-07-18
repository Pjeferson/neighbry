# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing::Faturas", type: :request do
  let(:condominium) { create(:condominium, slug: "acme") }
  let(:building) { create(:building, condominium: condominium) }
  let(:unit) { create(:unit, building: building) }
  let(:tenant_headers) { json_headers.merge("HOST" => "acme.example.com") }
  let(:admin) { create(:user, password: "secret123") }

  before { create(:membership, user: admin, condominium: condominium, role: "admin", status: "active") }

  def auth_headers_for(user, password: "secret123")
    post "/api/v1/auth/sign_in",
         params:  { user: { email: user.email, password: password } }.to_json,
         headers: tenant_headers
    tenant_headers.merge("Authorization" => response.headers["Authorization"])
  end

  describe "PATCH /api/v1/billing/faturas/:id/confirm_payment" do
    it "admin confirms payment manually" do
      fatura = create(:fatura, unit: unit, condominium: condominium)
      headers = auth_headers_for(admin)

      patch "/api/v1/billing/faturas/#{fatura.id}/confirm_payment", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "attributes", "status")).to eq("pago")
    end

    it "forbids a non-admin from confirming payment manually" do
      fatura = create(:fatura, unit: unit, condominium: condominium)
      owner = create(:user, password: "secret123")
      create(:membership, user: owner, condominium: condominium, role: "resident", status: "active")
      person = create(:person, condominium: condominium, user: owner)
      create(:occupancy, unit: unit, person: person, owner: true)
      headers = auth_headers_for(owner)

      patch "/api/v1/billing/faturas/#{fatura.id}/confirm_payment", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(fatura.reload).to be_pendente
    end

    it "returns 404 for a Fatura belonging to a different condominium" do
      other_fatura = create(:fatura)
      headers = auth_headers_for(admin)

      patch "/api/v1/billing/faturas/#{other_fatura.id}/confirm_payment", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
