# frozen_string_literal: true

module Notice
  class ConfirmLeitura
    include Dry::Monads[:result]

    def call(actor:, aviso:)
      return Failure(:aviso_inativo) unless aviso.ativo?

      leitura = Leitura.find_by(aviso: aviso, user: actor)
      return Failure(:not_a_destinatario) unless leitura

      leitura.update!(confirmado_em: leitura.confirmado_em || Time.current)
      Success(leitura)
    end
  end
end
