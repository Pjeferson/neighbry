# frozen_string_literal: true

class CreateAvisos < ActiveRecord::Migration[8.1]
  def change
    create_table :avisos, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.string :titulo, null: false
      t.text :corpo, null: false
      t.string :tipo, null: false
      t.references :building, type: :uuid, foreign_key: true
      t.references :unit, type: :uuid, foreign_key: true
      t.boolean :ativo, null: false, default: true
      t.references :criado_por, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps null: false
    end
  end
end
