# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tenancy isolation" do
  it "never references Registry directly (only Registry may know about Tenancy)" do
    tenancy_files = Dir[
      Rails.root.join("app/domains/tenancy/**/*.rb"),
      Rails.root.join("app/services/tenancy/**/*.rb"),
      Rails.root.join("app/policies/tenancy/**/*.rb"),
      Rails.root.join("app/serializers/tenancy/**/*.rb")
    ]

    offending = tenancy_files.select { |path| File.read(path).include?("Registry") }

    expect(offending).to be_empty
  end
end
