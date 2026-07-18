# frozen_string_literal: true

class CreateCondominiumBillingSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :condominium_billing_settings, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.integer :dia_cobranca, null: false
      t.integer :dias_para_vencimento, null: false

      t.timestamps null: false
    end
  end
end
