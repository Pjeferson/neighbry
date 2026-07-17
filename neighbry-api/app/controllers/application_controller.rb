# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_forbidden
    render json: { error: "forbidden" }, status: :forbidden
  end

  def render_not_found
    render json: { error: "not_found" }, status: :not_found
  end
end
