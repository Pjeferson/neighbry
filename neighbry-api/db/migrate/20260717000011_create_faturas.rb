# frozen_string_literal: true

class CreateFaturas < ActiveRecord::Migration[8.1]
  def change
    create_table :faturas, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :unit, null: false, type: :uuid, foreign_key: true
      t.references :ciclo_cobranca, null: false, type: :uuid, foreign_key: true
      t.string :status, null: false, default: "pendente"
      t.date :data_vencimento, null: false

      t.timestamps null: false
    end

    # Idempotência de geração por unidade dentro do mesmo ciclo — permite
    # retomar um CicloCobranca em `gerando` sem duplicar Fatura já criada
    # (ver design.md Decisão "Idempotência de Fatura e Pagamento").
    add_index :faturas, %i[ciclo_cobranca_id unit_id], unique: true,
      name: "index_faturas_on_ciclo_cobranca_id_and_unit_id"
  end
end
