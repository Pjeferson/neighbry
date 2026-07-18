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

- [x] 9.1 Specs de modelo — `Aviso` (validação condicional de tipo, imutabilidade), `Leitura` (índice único)
- [x] 9.2 Specs de serviço — `ResolveDestinatarios` (todos/moradores/staff/torre/unidade, dedupe de torre, Person sem User excluída), `CreateAviso`, `DeactivateAviso`, `ConfirmLeitura` (idempotência, rejeição se inativo, rejeição se não-destinatário)
- [x] 9.3 Specs de policy — `AvisoPolicy` (create?/view_painel? admin-only)
- [x] 9.4 Request specs — criação, desativação (aviso some da listagem do morador), confirmação (idempotente, rejeitada se inativo ou não-destinatário), listagem "meus avisos", painel admin-only

## 10. Validação E2E

- [x] 10.1 Validação manual via curl contra o servidor rodando: criação de aviso tipo `unidade` (1 destinatário) e `todos` (admin + moradores) ✓ → confirmação manual + idempotência (segunda chamada mesmo resultado) ✓ → não-destinatário rejeitado (`not_a_destinatario`, 422) ✓ → painel mostra contador correto (1/1) ✓ → desativação de Aviso `todos` faz sumir da listagem "meus avisos" do morador ✓ → confirmação em Aviso desativado rejeitada (`aviso_inativo`, 422) ✓ → staff não-admin (manager) forbidden no painel (422) ✓ → **dedupe de torre confirmado ao vivo**: mesma Person dona de 2 Unit na mesma Building conta como 1 único destinatário (`total_destinatarios: 2`, não 3, com 2 units do dono + 1 do morador)
