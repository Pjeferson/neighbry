# frozen_string_literal: true

module Registry
  class Building < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"

    validates :name, presence: true
  end
end
