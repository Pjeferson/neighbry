# frozen_string_literal: true

module Billing
  # Gera uma Fatura por Unit ativa (com ao menos uma Registry::Occupancy
  # ativa, qualquer papel) para o CicloCobranca informado. Retomável: só
  # processa unidades que ainda não têm Fatura nesse ciclo, então rodar de
  # novo sobre um ciclo em `gerando` não duplica nada (ver design.md
  # Decisão "CicloCobranca com status para retomada segura").
  class GenerateInvoicesForCycle
    def call(ciclo_cobranca:)
      condominium = ciclo_cobranca.condominium
      active_unit_ids = active_unit_ids_for(condominium)

      taxas_aplicaveis = Taxa.where(condominium: condominium, ativo: true)
        .select { |taxa| taxa.aplicavel?(ciclo_cobranca.competencia) }

      if active_unit_ids.any? && taxas_aplicaveis.any?
        pendentes = active_unit_ids - ciclo_cobranca.faturas.pluck(:unit_id)
        setting = CondominiumBillingSetting.find_by(condominium: condominium)
        data_vencimento = Date.current + setting.dias_para_vencimento.days

        pendentes.each do |unit_id|
          gerar_fatura(ciclo_cobranca, unit_id, taxas_aplicaveis, active_unit_ids.size, data_vencimento)
        end
      end

      ciclo_cobranca.concluir! unless ciclo_cobranca.concluido?
    end

    private

    def active_unit_ids_for(condominium)
      Registry::Unit
        .where(condominium_id: condominium.id)
        .where(id: Registry::Occupancy.where(end_date: nil).select(:unit_id))
        .distinct
        .pluck(:id)
    end

    def gerar_fatura(ciclo_cobranca, unit_id, taxas_aplicaveis, total_unidades_ativas, data_vencimento)
      cobrancas_attributes = taxas_aplicaveis.map do |taxa|
        {
          condominium_id: ciclo_cobranca.condominium_id,
          taxa_id: taxa.id,
          valor: (taxa.valor / total_unidades_ativas).round(2)
        }
      end

      Fatura.create!(
        condominium_id: ciclo_cobranca.condominium_id,
        unit_id: unit_id,
        ciclo_cobranca: ciclo_cobranca,
        data_vencimento: data_vencimento,
        cobrancas_attributes: cobrancas_attributes
      )
    rescue ActiveRecord::RecordInvalid
      # unit_id já faturada por uma execução concorrente — o índice único
      # (ciclo_cobranca_id, unit_id) protege; seguimos para a próxima.
      nil
    end
  end
end
