## 1. Migrations

- [x] 1.1 `avisos` (condominium_id, titulo, corpo, tipo, building_id nullable, unit_id nullable, ativo default true, criado_por/user_id)
- [x] 1.2 `leituras` (aviso_id, user_id, confirmado_em nullable) — índice único em (aviso_id, user_id)

## 2. Domain models (app/domains/notice/)

- [x] 2.1 `Notice::Aviso` — enum `tipo: todos/moradores/staff/torre/unidade`; validação condicional de `building_id`/`unit_id` conforme `tipo`; validação de imutabilidade (só `ativo` editável após persistido)
- [x] 2.2 `Notice::Leitura` — pertence a `Aviso`; `confirmado?` método de conveniência

## 3. Cálculo de destinatários

- [x] 3.1 `Notice::ResolveDestinatarios` service — retorna array de `user_id` únicos conforme `tipo`: `todos`/`moradores`/`staff` via `Tenancy::Membership` (por `role`, `status: active`); `torre`/`unidade` via `Registry::Occupancy` ativa (qualquer papel) → `Person.user_id`, filtrando nulos e deduplicando

## 4. Criação de Aviso (admin-only)

- [x] 4.1 `Notice::AvisoPolicy` — `create?` e `view_painel?` restritos a `Membership(role: admin)`
- [x] 4.2 `Notice::CreateAviso` service (`Dry::Monads::Result`) — valida policy, cria `Aviso` + uma `Leitura` por destinatário resolvido, numa única transação
- [x] 4.3 `Notice::AvisoSerializer`
- [x] 4.4 `POST /api/v1/notice/avisos` — controller + rota

## 5. Desativação de Aviso (admin-only)

- [x] 5.1 `Notice::DeactivateAviso` service — valida policy, marca `ativo: false`
- [x] 5.2 `PATCH /api/v1/notice/avisos/:id/deactivate` — controller + rota

## 6. Confirmação de leitura

- [x] 6.1 `Notice::ConfirmLeitura` service — rejeita se `Aviso.ativo` for `false`; rejeita se não existir `Leitura` para o `User` (não-destinatário); idempotente (`UPDATE`, não `INSERT`, no-op se já confirmado)
- [x] 6.2 `PATCH /api/v1/notice/avisos/:id/confirmar` — controller + rota

## 7. Listagem de avisos recebidos

- [x] 7.1 `GET /api/v1/notice/avisos` — lista `Aviso` ativos onde o `current_user` tem `Leitura`, incluindo se já confirmou ou não — controller + rota

## 8. Painel de confirmação (admin-only)

- [x] 8.1 `Notice::PainelSerializer` — total de destinatários, total de confirmados, lista de quem confirmou
- [x] 8.2 `GET /api/v1/notice/avisos/:id/painel` — controller escopado pela policy + rota

## 9. Testes

- [ ] 9.1 Specs de modelo — `Aviso` (validação condicional de tipo, imutabilidade), `Leitura` (índice único)
- [ ] 9.2 Specs de serviço — `ResolveDestinatarios` (todos/moradores/staff/torre/unidade, dedupe de torre, Person sem User excluída), `CreateAviso`, `DeactivateAviso`, `ConfirmLeitura` (idempotência, rejeição se inativo, rejeição se não-destinatário)
- [ ] 9.3 Specs de policy — `AvisoPolicy` (create?/view_painel? admin-only)
- [ ] 9.4 Request specs — criação, desativação (aviso some da listagem do morador), confirmação (idempotente, rejeitada se inativo ou não-destinatário), listagem "meus avisos", painel admin-only

## 10. Validação E2E

- [ ] 10.1 Validação manual via curl contra o servidor rodando: criação de aviso por tipo (todos/moradores/staff/torre/unidade) → snapshot de destinatários correto (incluindo dedupe de torre) → confirmação manual → painel mostra contador correto → desativação → aviso some da listagem do morador e confirmação passa a ser rejeitada
