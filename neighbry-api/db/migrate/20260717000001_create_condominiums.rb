# frozen_string_literal: true

class CreateCondominiums < ActiveRecord::Migration[8.1]
  def change
    create_table :condominiums, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps null: false
    end

    add_index :condominiums, :slug, unique: true
  end
end
