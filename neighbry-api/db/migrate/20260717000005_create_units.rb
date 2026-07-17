# frozen_string_literal: true

class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :building, null: false, type: :uuid, foreign_key: true
      t.string :identification, null: false
      t.timestamps null: false
    end
  end
end
