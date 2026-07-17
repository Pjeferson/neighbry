# frozen_string_literal: true

class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :user, null: true, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :cpf, null: false
      t.string :type, null: false
      # Referência a Tenancy::Invitation por id — nunca FK real (cross-context,
      # ver design.md Decisão 9). Nullable e transitório: limpo na reconciliação.
      t.uuid :pending_invitation_id

      t.timestamps null: false
    end

    add_index :people, %i[condominium_id cpf], unique: true
  end
end
