# frozen_string_literal: true

class CreateLeituras < ActiveRecord::Migration[8.1]
  def change
    create_table :leituras, id: :uuid do |t|
      t.references :aviso, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.datetime :confirmado_em

      t.timestamps null: false
    end

    # Idempotência de confirmação e defesa contra destinatário duplicado no
    # snapshot (ex: Person com Occupancy em duas Unit da mesma torre) — ver
    # design.md Decisão "Deduplicação obrigatória no cálculo de torre".
    add_index :leituras, %i[aviso_id user_id], unique: true
  end
end
