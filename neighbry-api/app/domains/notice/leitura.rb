# frozen_string_literal: true

module Notice
  class Leitura < ApplicationRecord
    belongs_to :aviso, class_name: "Notice::Aviso"
    belongs_to :user

    def confirmado?
      confirmado_em.present?
    end
  end
end
