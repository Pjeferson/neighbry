## 1. Estrutura do módulo

- [x] 1.1 Criar `app/domains/registry/`, `app/services/registry/`, `app/policies/registry/`, `app/serializers/registry/`
- [x] 1.2 Confirmar autoload via `Rails.autoloaders.main.dirs` (mesmo padrão validado em `add-tenancy`, não deve precisar de configuração extra)

## 2. Migrations

- [x] 2.1 Migration `buildings` (id uuid, condominium_id FK, name, timestamps)
- [x] 2.2 Migration `units` (id uuid, condominium_id FK, building_id FK, identification, timestamps)
- [x] 2.3 Migration `people` (id uuid, condominium_id FK, user_id FK nullable, name, cpf, type enum, pending_invitation_id nullable, timestamps; índice único em `(condominium_id, cpf)`)
- [x] 2.4 Migration `occupancies` (id uuid, condominium_id FK, unit_id FK, person_id FK, owner boolean default false, responsible boolean default false, start_date, end_date nullable, timestamps)
- [x] 2.5 Índices parciais únicos: `occupancies` com no máx. 1 linha `owner: true` ativa por `unit_id`, no máx. 1 linha `responsible: true` ativa por `unit_id` — e também no máx. 1 `Occupancy` ativa por `(person_id, unit_id)` (Decisão 10)
- [x] 2.6 Rodar migrations em development e test

## 3. Building

- [x] 3.1 Model `Registry::Building` — `belongs_to :condominium`, validação de `name`
- [x] 3.2 Factory + testes de invariante (Building sem Condominium é rejeitado)

## 4. Unit

- [x] 4.1 Model `Registry::Unit` — `belongs_to :building`, `condominium_id` denormalizado e validado consistente com o `Building`
- [x] 4.2 Factory + testes de invariante (Unit sem Building é rejeitado)

## 5. Person

- [x] 5.1 Model `Registry::Person` — `belongs_to :condominium`, `belongs_to :user, optional: true`, enum `type: resident | service_provider`, validação de CPF (formato/dígito verificador) — `self.inheritance_column = nil` pra desligar STI, já que `type` é nome de coluna reservado do Rails
- [x] 5.2 Unicidade `(condominium_id, cpf)`
- [x] 5.3 Factory (com gerador de CPF válido) + testes de validação (formato, dígito verificador, unicidade por condomínio, mesmo CPF permitido em condomínio diferente). A reutilização de Person por CPF em `RegisterOccupant` é testada no Grupo 8, não aqui (é comportamento do service, não do model)

## 6. Occupancy

- [x] 6.1 Model `Registry::Occupancy` — `belongs_to :unit`, `belongs_to :person`, `condominium_id` denormalizado, flags `owner`/`responsible` — também valida que `person.condominium_id == unit.condominium_id` (invariante implícito, não listado originalmente, mas necessário)
- [x] 6.2 Validação: `owner` e `responsible` nunca `true` simultaneamente na mesma Occupancy
- [x] 6.3 Validação/constraint: no máx. 1 `owner` ativo por Unit, no máx. 1 `responsible` ativo por Unit (nível de aplicação + índice parcial do banco, defesa em profundidade — mesmo padrão de `add-tenancy`)
- [x] 6.4 Método `#end!` pra encerrar (`end_date = hoje`) sem apagar o registro (append-only, histórico preservado)
- [x] 6.5 Validação: rejeitar segunda `Occupancy` ativa pra mesma `Person`+`Unit` (não idempotente, erro de validação — ver design.md Decisão 10)
- [x] 6.6 Factory + testes: segundo owner/responsible ativo rejeitado, mesma Person em várias Unit do mesmo condomínio sem conflito, cadastro duplicado da mesma Person na mesma Unit rejeitado

## 7. Autorização (Pundit)

- [x] 7.1 `Registry::OccupancyPolicy(user, unit)` — `create_owner?`/`create_responsible?`/`create_occupant?` e `end_owner?`/`end_responsible?`/`end_occupant?`. admin (via `Tenancy::Membership`) sempre permitido; `owner` só a própria Unit (e só `responsible`/morador comum); `responsible` só a própria Unit (e só morador comum)
- [x] 7.2 Regra explícita: `end_owner?` só admin — mesmo o próprio `owner` não pode
- [x] 7.3 Regra explícita: `end_responsible?` não é permitido pro próprio `responsible` — só admin ou `owner` da Unit
- [x] 7.4 `Registry::ServiceProviderPolicy(user, condominium)` — `create?`: admin (qualquer unidade do condomínio) ou qualquer `Person` com `owner`/`responsible` ativo em alguma Unit desse condomínio; sem nenhum dos dois é rejeitado
- [x] 7.5 Testes de policy cobrindo os cenários acima, incluindo: admin permite tudo, owner não mexe em Unit alheia, responsible só cadastra morador comum, sem role nenhuma rejeita tudo, sem user rejeita tudo

## 8. RegisterOccupant

- [x] 8.1 Service `Registry::RegisterOccupant(actor:, unit:, person_attributes:, owner:, responsible:, grant_access:, email: nil)` (Dry::Monads::Result) — busca `Person` por CPF no condomínio, reaproveita ou cria; cria `Occupancy`. `email:` obrigatório apenas quando `grant_access: true` (ver design.md Decisão 8 — nunca persistido em `Person`). Também rejeita (`:person_type_mismatch`) reaproveitar um CPF já cadastrado como `service_provider` (Decisão do `Person.type` fixo)
- [x] 8.2 Quando `grant_access: true`: checa antes se o `email` já corresponde a `User` com `Membership` ativo — se sim, rejeita sem criar `Invitation` (design.md Decisão 9); senão, chama `Tenancy::InviteMember` **antes** de tocar no banco de Registry (assim uma falha no convite não deixa Person/Occupancy órfã) — service público, chamada síncrona direta, ver design.md Decisão 6; guarda o `invitation.id` retornado em `Person.pending_invitation_id`
- [x] 8.3 Quando `grant_access: false`: nenhum convite é criado, `email` não é exigido
- [x] 8.4 Factory + testes cobrindo os fluxos mapeados (um teste por fluxo, verificando Occupancy criada com os flags certos e a policy do Grupo 7 respeitada):
  - admin cadastra dono de uma Unit
  - admin cadastra responsible de uma Unit diretamente, sem dono cadastrado antes
  - owner delega responsible na própria Unit
  - owner tenta definir responsible em Unit alheia — rejeitado
  - responsible cadastra morador comum na própria Unit
  - morador comum tenta cadastrar alguém — rejeitado
  - `grant_access: true` com email que já tem Membership — rejeitado, nenhum Invitation criado
  - CPF já existente no condomínio reaproveita a Person (não duplica)
  - CPF já cadastrado como service_provider é rejeitado como ocupante

## 9. RegisterServiceProvider

- [x] 9.1 Service `Registry::RegisterServiceProvider(actor:, condominium:, person_attributes:, grant_access:, email: nil)` — busca/cria `Person(type: service_provider)` por CPF (mesmo padrão de reconciliação do Grupo 8, incluindo rejeição se o CPF já é `resident`), sem `Unit`/`Occupancy`
- [x] 9.2 Mesma checagem do 8.2 (email já com Membership rejeita antes de convidar)
- [x] 9.3 Testes: prestador nunca gera Occupancy; concessão de acesso opcional segue o mesmo caminho do Grupo 8.2; admin cadastra prestador; owner cadastra prestador; morador comum sem flag tentando cadastrar prestador é rejeitado (policy do Grupo 7.4); email já com Membership rejeitado; CPF já `resident` rejeitado

## 10. EndOccupancy

- [x] 10.1 Service `Registry::EndOccupancy(actor:, occupancy:)` — encerra (`end_date`) via `Occupancy#end!`, respeitando a policy do Grupo 7 (varia conforme owner/responsible/morador comum da Occupancy sendo encerrada)
- [x] 10.2 Testes: admin encerra owner; owner não encerra a própria titularidade; owner encerra responsible; responsible não encerra a si mesmo; responsible encerra morador comum; outro morador comum não encerra Occupancy alheia

## 11. Ajustes em Tenancy — evento de aceite e convite pendente substituído

- [x] 11.1 Em `Tenancy::AcceptInvitation`: publica `ActiveSupport::Notifications.instrument("tenancy.invitation_accepted", invitation_id:, user_id:)` — sem qualquer referência a `Registry` no código
- [x] 11.2 Testes em `Tenancy` confirmando que o evento é publicado no aceite (capturado via `ActiveSupport::Notifications.subscribed`), e teste estático (`isolation_spec.rb`) garantindo que nenhum arquivo de `app/*/tenancy/` menciona "Registry"
- [x] 11.3 `Registry::ReconcilePersonUser` + assinatura em `config/initializers/domain_events.rb` — busca `Person` por `pending_invitation_id == invitation_id` e preenche `Person.user_id`, limpando `pending_invitation_id`. Idempotente (rodar duas vezes pro mesmo invitation_id não faz nada na segunda)
- [x] 11.4 Testes: fluxo de ponta a ponta real (`spec/integration/`) — `RegisterOccupant` com `grant_access` → `AcceptInvitation` → `Person.user_id` preenchido; convite de staff (sem `Person` nenhuma envolvida) não afeta `Registry::Person.count`
- [x] 11.5 Em `Tenancy::InviteMember`: antes de criar um novo `Invitation`, invalida (`expires_at` no passado) qualquer `Invitation` pendente do mesmo email no mesmo `Condominium` — reaproveita o mecanismo de expiração existente, sem coluna/estado novo (substitui a ideia anterior de um service de reenvio dedicado)
- [x] 11.6 Testes: convidar de novo invalida o convite pendente anterior (novo id, antigo expirado); convite já aceito não é afetado por um novo convite pro mesmo email

## 12. Rotas e serializers

- [x] 12.1 Rotas em inglês sob `/api/v1/`: `POST /units/:unit_id/occupancies` (cadastro de ocupante), `POST /service_providers` (cadastro de prestador), `PATCH /occupancies/:id/close` (encerramento — não pode ser `end`, palavra reservada do Ruby, `def end` não compila). Nenhuma rota nova pra "reenviar convite" — reusa a rota de convite existente em Tenancy
- [x] 12.2 Serializers (`jsonapi-serializer`) para `Building`, `Unit`, `Person`, `Occupancy`. `ApplicationController` ganhou `rescue_from ActiveRecord::RecordNotFound` (404 json) — necessário pros controllers novos que buscam Unit/Occupancy escopados por tenant via `find_by!`

## 13. Validação final

- [x] 13.1 `bundle exec rspec` roda sem falhas — 149 exemplos, 0 falhas
- [x] 13.2 `docker compose restart` sobe sem erro com as novas migrations aplicadas — confirmado, `GET /up` retorna 200
- [x] 13.3 Fluxo manual de ponta a ponta validado via curl contra o servidor real (`*.localhost:3001`): admin cadastra dono com acesso → convite aceito → `Person.user_id` reconciliado via evento (confirmado no banco, não por email) → dono loga → dono delega responsible com acesso → responsible aceita e loga → responsible cadastra morador comum → owner tenta encerrar a própria titularidade → 422 (rejeitado corretamente)
- [x] 13.4 `CLAUDE.md` já cobre o padrão de módulos genericamente (já cita "Registry" na regra 8) — confirmado, nenhuma mudança necessária

## 14. Cadastro de Building e Unit (gap encontrado após a primeira validação — ver design.md Decisão 11)

- [ ] 14.1 `Registry::AdminCheckable` — módulo compartilhado com a checagem "é admin desse condomínio" (extraído de `OccupancyPolicy`/`ServiceProviderPolicy`, que passam a incluí-lo também, sem mudar comportamento)
- [ ] 14.2 `Registry::BuildingPolicy(user, condominium)` — `create?`: só admin
- [ ] 14.3 `Registry::UnitPolicy(user, building)` — `create?`: só admin do condomínio do Building
- [ ] 14.4 Service `Registry::RegisterBuilding(actor:, condominium:, name:)` (Dry::Monads::Result)
- [ ] 14.5 Service `Registry::RegisterUnit(actor:, building:, identification:)` (Dry::Monads::Result)
- [ ] 14.6 Rotas: `POST /api/v1/buildings` (condomínio resolvido por subdomínio, mesmo padrão de `service_providers`), `POST /api/v1/buildings/:building_id/units`
- [ ] 14.7 Controllers finos usando os serializers já existentes (`BuildingSerializer`, `UnitSerializer`)
- [ ] 14.8 Testes: admin cadastra Building; não-admin (incluindo owner/responsible) rejeitado; admin cadastra Unit num Building do próprio condomínio; Building de outro condomínio retorna 404 (mesmo padrão de escopo por tenant já usado em `units/:unit_id/occupancies`)

## 15. Validação final (pós-Grupo 14)

- [ ] 15.1 `bundle exec rspec` roda sem falhas
- [ ] 15.2 Fluxo manual: admin cria Building + Unit pela API (sem precisar de `rails console`) → segue o mesmo fluxo de ponta a ponta já validado no Grupo 13 a partir daí
