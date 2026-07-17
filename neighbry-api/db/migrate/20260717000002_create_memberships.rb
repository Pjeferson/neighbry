# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships, id: :uuid do |t|
      # 1:1 no v1 — um User tem no máximo um Membership (ver design.md Decisão 6)
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.string :role, null: false
      t.string :status, null: false, default: "active"
      t.timestamps null: false
    end
  end
end
