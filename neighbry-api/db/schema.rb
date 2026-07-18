# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_17_000015) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "avisos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.uuid "building_id"
    t.uuid "condominium_id", null: false
    t.text "corpo", null: false
    t.datetime "created_at", null: false
    t.uuid "criado_por_id", null: false
    t.string "tipo", null: false
    t.string "titulo", null: false
    t.uuid "unit_id"
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_avisos_on_building_id"
    t.index ["condominium_id"], name: "index_avisos_on_condominium_id"
    t.index ["criado_por_id"], name: "index_avisos_on_criado_por_id"
    t.index ["unit_id"], name: "index_avisos_on_unit_id"
  end

  create_table "buildings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["condominium_id"], name: "index_buildings_on_condominium_id"
  end

  create_table "ciclo_cobrancas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "competencia", null: false
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "gerando", null: false
    t.datetime "updated_at", null: false
    t.index ["condominium_id", "competencia"], name: "index_ciclo_cobrancas_on_condominium_id_and_competencia", unique: true
    t.index ["condominium_id"], name: "index_ciclo_cobrancas_on_condominium_id"
  end

  create_table "cobrancas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.uuid "fatura_id", null: false
    t.uuid "taxa_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 12, scale: 2, null: false
    t.index ["condominium_id"], name: "index_cobrancas_on_condominium_id"
    t.index ["fatura_id"], name: "index_cobrancas_on_fatura_id"
    t.index ["taxa_id"], name: "index_cobrancas_on_taxa_id"
  end

  create_table "condominium_billing_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.integer "dia_cobranca", null: false
    t.integer "dias_para_vencimento", null: false
    t.datetime "updated_at", null: false
    t.index ["condominium_id"], name: "index_condominium_billing_settings_on_condominium_id", unique: true
  end

  create_table "condominiums", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_condominiums_on_slug", unique: true
  end

  create_table "faturas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "ciclo_cobranca_id", null: false
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.date "data_vencimento", null: false
    t.string "status", default: "pendente", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ciclo_cobranca_id", "unit_id"], name: "index_faturas_on_ciclo_cobranca_id_and_unit_id", unique: true
    t.index ["ciclo_cobranca_id"], name: "index_faturas_on_ciclo_cobranca_id"
    t.index ["condominium_id"], name: "index_faturas_on_condominium_id"
    t.index ["unit_id"], name: "index_faturas_on_unit_id"
  end

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "accepted_at"
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.string "role", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["condominium_id"], name: "index_invitations_on_condominium_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "jwt_denylists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "leituras", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "aviso_id", null: false
    t.datetime "confirmado_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["aviso_id", "user_id"], name: "index_leituras_on_aviso_id_and_user_id", unique: true
    t.index ["aviso_id"], name: "index_leituras_on_aviso_id"
    t.index ["user_id"], name: "index_leituras_on_user_id"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["condominium_id"], name: "index_memberships_on_condominium_id"
    t.index ["user_id"], name: "index_memberships_on_user_id", unique: true
  end

  create_table "occupancies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.boolean "owner", default: false, null: false
    t.uuid "person_id", null: false
    t.boolean "responsible", default: false, null: false
    t.date "start_date", null: false
    t.uuid "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["condominium_id"], name: "index_occupancies_on_condominium_id"
    t.index ["person_id", "unit_id"], name: "index_occupancies_on_person_id_and_unit_id_active", unique: true, where: "(end_date IS NULL)"
    t.index ["person_id"], name: "index_occupancies_on_person_id"
    t.index ["unit_id"], name: "index_occupancies_on_unit_id"
    t.index ["unit_id"], name: "index_occupancies_on_unit_id_active_owner", unique: true, where: "((owner = true) AND (end_date IS NULL))"
    t.index ["unit_id"], name: "index_occupancies_on_unit_id_active_responsible", unique: true, where: "((responsible = true) AND (end_date IS NULL))"
  end

  create_table "pagamentos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.datetime "data", null: false
    t.uuid "fatura_id", null: false
    t.string "metodo", null: false
    t.string "transaction_id"
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 12, scale: 2, null: false
    t.index ["condominium_id"], name: "index_pagamentos_on_condominium_id"
    t.index ["fatura_id"], name: "index_pagamentos_on_fatura_id", unique: true
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "condominium_id", null: false
    t.string "cpf", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "pending_invitation_id"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["condominium_id", "cpf"], name: "index_people_on_condominium_id_and_cpf", unique: true
    t.index ["condominium_id"], name: "index_people_on_condominium_id"
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "taxas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "ativo", default: true, null: false
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.date "data_fim"
    t.date "data_inicio", null: false
    t.string "descricao", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 12, scale: 2, null: false
    t.index ["condominium_id"], name: "index_taxas_on_condominium_id"
  end

  create_table "units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "building_id", null: false
    t.uuid "condominium_id", null: false
    t.datetime "created_at", null: false
    t.string "identification", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_units_on_building_id"
    t.index ["condominium_id"], name: "index_units_on_condominium_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "avisos", "buildings"
  add_foreign_key "avisos", "condominiums"
  add_foreign_key "avisos", "units"
  add_foreign_key "avisos", "users", column: "criado_por_id"
  add_foreign_key "buildings", "condominiums"
  add_foreign_key "ciclo_cobrancas", "condominiums"
  add_foreign_key "cobrancas", "condominiums"
  add_foreign_key "cobrancas", "faturas"
  add_foreign_key "cobrancas", "taxas"
  add_foreign_key "condominium_billing_settings", "condominiums"
  add_foreign_key "faturas", "ciclo_cobrancas"
  add_foreign_key "faturas", "condominiums"
  add_foreign_key "faturas", "units"
  add_foreign_key "invitations", "condominiums"
  add_foreign_key "leituras", "avisos"
  add_foreign_key "leituras", "users"
  add_foreign_key "memberships", "condominiums"
  add_foreign_key "memberships", "users"
  add_foreign_key "occupancies", "condominiums"
  add_foreign_key "occupancies", "people"
  add_foreign_key "occupancies", "units"
  add_foreign_key "pagamentos", "condominiums"
  add_foreign_key "pagamentos", "faturas"
  add_foreign_key "people", "condominiums"
  add_foreign_key "people", "users"
  add_foreign_key "taxas", "condominiums"
  add_foreign_key "units", "buildings"
  add_foreign_key "units", "condominiums"
end
