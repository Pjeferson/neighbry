# frozen_string_literal: true

module Notice
  class Aviso < ApplicationRecord
    belongs_to :condominium, class_name: "Tenancy::Condominium"
    belongs_to :building, class_name: "Registry::Building", optional: true
    belongs_to :unit, class_name: "Registry::Unit", optional: true
    belongs_to :criado_por, class_name: "User"
    has_many :leituras, class_name: "Notice::Leitura", dependent: :destroy

    enum :tipo, { todos: "todos", moradores: "moradores", staff: "staff", torre: "torre", unidade: "unidade" },
      validate: true

    validates :titulo, presence: true
    validates :corpo, presence: true
    validate :building_unit_consistency
    validate :immutable_fields, on: :update

    private

    def building_unit_consistency
      case tipo
      when "torre"
        errors.add(:building_id, "must be present when tipo is torre") if building_id.blank?
        errors.add(:unit_id, "must be blank when tipo is torre") if unit_id.present?
      when "unidade"
        errors.add(:unit_id, "must be present when tipo is unidade") if unit_id.blank?
        errors.add(:building_id, "must be blank when tipo is unidade") if building_id.present?
      else
        errors.add(:building_id, "must be blank for this tipo") if building_id.present?
        errors.add(:unit_id, "must be blank for this tipo") if unit_id.present?
      end
    end

    def immutable_fields
      %i[titulo corpo tipo building_id unit_id].each do |attribute|
        errors.add(attribute, "cannot be changed after creation") if attribute_changed?(attribute)
      end
    end
  end
end
