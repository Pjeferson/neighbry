# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResolvesTenant, type: :request do
  before do
    stub_const("ResolvesTenantTestController", Class.new(ApplicationController) do
      include ResolvesTenant

      def index
        render json: { condominium_id: Tenancy::Current.condominium.id }
      end
    end)

    Rails.application.routes.draw do
      get "/resolves_tenant_test" => "resolves_tenant_test#index"
    end
  end

  after { Rails.application.reload_routes! }

  it "resolves the Condominium from the subdomain" do
    condominium = create(:condominium, slug: "acme")

    get "/resolves_tenant_test", headers: { "HOST" => "acme.example.com" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["condominium_id"]).to eq(condominium.id)
  end

  it "returns 404 when no Condominium matches the subdomain" do
    get "/resolves_tenant_test", headers: { "HOST" => "unknown.example.com" }

    expect(response).to have_http_status(:not_found)
  end
end
