# frozen_string_literal: true

class CreateCobrancas < ActiveRecord::Migration[8.1]
  def change
    create_table :cobrancas, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :fatura, null: false, type: :uuid, foreign_key: true
      t.references :taxa, null: false, type: :uuid, foreign_key: true
      t.decimal :valor, precision: 12, scale: 2, null: false

      t.timestamps null: false
    end
  end
end
