# frozen_string_literal: true

class CreateOccupancies < ActiveRecord::Migration[8.1]
  def change
    create_table :occupancies, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :unit, null: false, type: :uuid, foreign_key: true
      t.references :person, null: false, type: :uuid, foreign_key: true
      t.boolean :owner, null: false, default: false
      t.boolean :responsible, null: false, default: false
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps null: false
    end

    # No máx. 1 owner ativo e 1 responsible ativo por Unit — defesa em
    # profundidade a nível de banco, além da validação no model (ver
    # design.md Decisão 2 / tasks.md 6.3).
    add_index :occupancies, :unit_id, unique: true,
      where: "owner = true AND end_date IS NULL",
      name: "index_occupancies_on_unit_id_active_owner"
    add_index :occupancies, :unit_id, unique: true,
      where: "responsible = true AND end_date IS NULL",
      name: "index_occupancies_on_unit_id_active_responsible"

    # No máx. 1 Occupancy ativa por Person+Unit (independente dos flags) —
    # ver design.md Decisão 10.
    add_index :occupancies, %i[person_id unit_id], unique: true,
      where: "end_date IS NULL",
      name: "index_occupancies_on_person_id_and_unit_id_active"
  end
end
