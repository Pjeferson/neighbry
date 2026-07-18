## 1. Migration

- [x] 1.1 `common_areas` (condominium_id, nome, descricao, capacidade, horario_funcionamento, regras_uso, ativo default true)

## 2. Domain model

- [x] 2.1 `CommonArea::CommonArea` — validações de presença (`nome`, `capacidade`); sem restrição de imutabilidade

## 3. Cadastro e edição (admin-only)

- [x] 3.1 `CommonArea::AdminCheckable` module (mesmo padrão replicado em cada bounded context)
- [x] 3.2 `CommonArea::CommonAreaPolicy` — `create?`/`update?` restritos a `Membership(role: admin)` (`list?` também incluído aqui, usado no Grupo 4)
- [x] 3.3 `CommonArea::RegisterCommonArea` service (`Dry::Monads::Result`)
- [x] 3.4 `CommonArea::UpdateCommonArea` service — atualização livre de qualquer campo, admin-only
- [x] 3.5 `CommonArea::CommonAreaSerializer`
- [x] 3.6 `POST /api/v1/common_areas` e `PATCH /api/v1/common_areas/:id` — controller + rotas

## 4. Listagem (leitura aberta)

- [x] 4.1 `GET /api/v1/common_areas` — qualquer `Membership` ativo no condomínio, inclui `CommonArea` com `ativo: false` — controller + rota

## 5. Testes

- [x] 5.1 Specs de modelo — validações de presença
- [x] 5.2 Specs de serviço — `RegisterCommonArea`, `UpdateCommonArea` (admin-only, edição livre mesmo após criado)
- [x] 5.3 Specs de policy — `CommonAreaPolicy` (create?/update? admin-only)
- [x] 5.4 Request specs — cadastro, edição, listagem (aberta a qualquer role, inclui inativos), rejeição de Membership revogada

## 6. Validação E2E

- [ ] 6.1 Validação manual via curl contra o servidor rodando: admin cadastra CommonArea → admin edita campo já criado → morador consulta listagem (inclusive CommonArea desativado) → staff consulta listagem → usuário sem Membership é rejeitado
