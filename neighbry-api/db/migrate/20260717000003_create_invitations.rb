# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.string :email, null: false
      t.string :role, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.timestamps null: false
    end

    add_index :invitations, :token, unique: true
  end
end
