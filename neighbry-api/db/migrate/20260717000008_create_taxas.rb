# frozen_string_literal: true

class CreateTaxas < ActiveRecord::Migration[8.1]
  def change
    create_table :taxas, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.decimal :valor, precision: 12, scale: 2, null: false
      t.string :descricao, null: false
      t.date :data_inicio, null: false
      t.date :data_fim
      t.boolean :ativo, null: false, default: true

      t.timestamps null: false
    end
  end
end
