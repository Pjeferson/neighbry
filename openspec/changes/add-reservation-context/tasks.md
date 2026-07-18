## 1. Migration

- [x] 1.1 `bookings` (condominium_id, common_area_id, occupancy_id, unit_id, data, competencia, turno, cancelada_em)
- [x] 1.2 Índice único parcial `[:common_area_id, :data, :turno]` `where: "(cancelada_em IS NULL)"`
- [x] 1.3 Índice único parcial `[:unit_id, :common_area_id, :competencia]` `where: "(cancelada_em IS NULL)"`

## 2. Domain model

- [x] 2.1 `Reservation::Booking` — `belongs_to :condominium`, `:common_area` (`class_name: "CommonArea::CommonArea"`), `:occupancy` (`class_name: "Registry::Occupancy"`); `enum :turno, { manha:, tarde:, noite: }, validate: true`
- [x] 2.2 `before_validation` — preenche `unit_id` a partir de `occupancy.unit_id` e `competencia` a partir de `data.beginning_of_month` (mesmo idioma de `Registry::Unit#set_condominium_from_building`)
- [x] 2.3 Validação: `occupancy` ativa (`end_date: nil`) com `owner: true` ou `responsible: true`
- [x] 2.4 Validação: `data` não passada e no máximo 30 dias à frente da data atual
- [x] 2.5 Validação: `common_area.ativo?`
- [x] 2.6 Validação: unidade não tem outra `Booking` ativa pro mesmo `common_area` na mesma `competencia`
- [x] 2.7 `cancel!` — preenche `cancelada_em`

## 3. Criação de reserva (dono/responsável)

- [x] 3.1 `Reservation::BookingPolicy` — `create?` restrito a `User` com `Occupancy` ativa (`owner` ou `responsible`) na unidade correspondente; `list?` aberto a qualquer `Membership` ativo; `cancel?` restrito ao autor da `Booking`
- [x] 3.2 `Reservation::CreateBooking` service (`Dry::Monads::Result`) — cria `Booking`, faz `rescue ActiveRecord::RecordNotUnique`/`RecordInvalid` para corrida concorrente nos dois índices únicos parciais (turno e limite mensal por unidade — mesmo padrão de `Billing::GenerateBillingCycle`)
- [x] 3.3 `Reservation::BookingSerializer`
- [x] 3.4 `POST /api/v1/reservations` — controller + rota

## 4. Cancelamento (self-service)

- [x] 4.1 `Reservation::CancelBooking` service — chama `Booking#cancel!`, valida autoria via policy
- [x] 4.2 `DELETE /api/v1/reservations/:id` — controller + rota

## 5. Listagem (leitura aberta)

- [x] 5.1 `GET /api/v1/reservations` — qualquer `Membership` ativo no condomínio — controller + rota

## 6. Testes

- [ ] 6.1 Specs de modelo — validações de janela de data, `common_area.ativo?`, papel de `occupancy`, limite mensal por unidade, ambos os índices únicos parciais (incluindo teste de corrida/concorrência para criação simultânea no mesmo turno e para criação simultânea na mesma unidade/espaço/mês)
- [ ] 6.2 Specs de serviço — `CreateBooking` (sucesso, rejeição por papel/janela/inatividade/conflito de turno/limite mensal por unidade), `CancelBooking` (sucesso, rejeição por autoria, liberação do limite mensal após cancelar)
- [ ] 6.3 Specs de policy — `BookingPolicy` (create?/cancel?/list?)
- [ ] 6.4 Request specs — criação, cancelamento, listagem (aberta a qualquer role), rejeição por Membership revogada

## 7. Validação E2E

- [ ] 7.1 Validação manual via curl contra o servidor rodando: dono cadastra `Booking` ✓ → segunda tentativa no mesmo espaço/data/turno é rejeitada ✓ → segunda tentativa da mesma unidade no mesmo espaço em turno/dia diferente do mesmo mês é rejeitada pelo limite mensal ✓ → dono cancela sua reserva ✓ → novo `Booking` no mesmo turno e no mesmo mês/espaço, agora liberado, é aceito ✓ → morador sem papel de dono/responsável tenta reservar → rejeitado ✓ → listagem consultada por morador qualquer ✓
