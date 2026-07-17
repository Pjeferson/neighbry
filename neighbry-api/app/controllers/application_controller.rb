# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def render_forbidden
    render json: { error: "forbidden" }, status: :forbidden
  end
end
