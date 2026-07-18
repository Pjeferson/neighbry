# frozen_string_literal: true

class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings, id: :uuid do |t|
      t.references :condominium, null: false, type: :uuid, foreign_key: true
      t.references :common_area, null: false, type: :uuid, foreign_key: true
      t.references :occupancy, null: false, type: :uuid, foreign_key: true
      t.references :unit, null: false, type: :uuid, foreign_key: true
      t.date :data, null: false
      t.date :competencia, null: false
      t.string :turno, null: false
      t.datetime :cancelada_em

      t.timestamps null: false
    end

    # No máx. 1 Booking ativa por CommonArea+data+turno — defesa em
    # profundidade a nível de banco (ver design.md Decisão de concorrência).
    add_index :bookings, %i[common_area_id data turno], unique: true,
      where: "cancelada_em IS NULL",
      name: "index_bookings_on_common_area_data_turno_active"

    # No máx. 1 Booking ativa por Unit+CommonArea+competencia — limite de
    # justiça de uso, independente de turno (ver design.md).
    add_index :bookings, %i[unit_id common_area_id competencia], unique: true,
      where: "cancelada_em IS NULL",
      name: "index_bookings_on_unit_common_area_competencia_active"
  end
end
