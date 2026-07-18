# frozen_string_literal: true

class CreatePagamentos < ActiveRecord::Migration[8.1]
  def change
    create_table :pagamentos, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :fatura, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.string :metodo, null: false
      t.decimal :valor, precision: 12, scale: 2, null: false
      t.datetime :data, null: false
      t.string :transaction_id

      t.timestamps null: false
    end
  end
end
