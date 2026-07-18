# frozen_string_literal: true

class CreateCommonAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :common_areas, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.string :nome, null: false
      t.text :descricao
      t.integer :capacidade, null: false
      t.string :horario_funcionamento
      t.text :regras_uso
      t.boolean :ativo, null: false, default: true

      t.timestamps null: false
    end
  end
end
