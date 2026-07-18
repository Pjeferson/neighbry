# frozen_string_literal: true

class CreateCicloCobrancas < ActiveRecord::Migration[8.1]
  def change
    create_table :ciclo_cobrancas, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.date :competencia, null: false
      t.string :status, null: false, default: "gerando"

      t.timestamps null: false
    end

    # Idempotência: no máx. 1 ciclo por condomínio por competência, mesmo com
    # dia_cobranca mudando no meio do mês (ver design.md Decisão 2).
    add_index :ciclo_cobrancas, %i[condominium_id competencia], unique: true,
      name: "index_ciclo_cobrancas_on_condominium_id_and_competencia"
  end
end
