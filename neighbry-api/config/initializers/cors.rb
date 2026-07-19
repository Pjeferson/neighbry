# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Vite dev server — host genérico ou qualquer subdomínio de tenant
    # (ex: acme.localhost:5173), já que a base da API no frontend é
    # derivada do hostname atual (ver design.md, frontend-auth-onboarding).
    origins(/\Ahttp:\/\/([a-z0-9-]+\.)?localhost:5173\z/)

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization],
      max_age: 600
  end
end
