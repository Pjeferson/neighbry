# frozen_string_literal: true

module Tenancy
  class Condominium < ApplicationRecord
    SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  end
end
