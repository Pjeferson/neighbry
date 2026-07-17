# frozen_string_literal: true

class CreateBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :buildings, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.timestamps null: false
    end
  end
end
