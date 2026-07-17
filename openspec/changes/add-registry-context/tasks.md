## 1. Estrutura do módulo

- [ ] 1.1 Criar `app/domains/registry/`, `app/services/registry/`, `app/policies/registry/`, `app/serializers/registry/`
- [ ] 1.2 Confirmar autoload via `Rails.autoloaders.main.dirs` (mesmo padrão validado em `add-tenancy`, não deve precisar de configuração extra)

## 2. Migrations

- [ ] 2.1 Migration `buildings` (id uuid, condominium_id FK, name, timestamps)
- [ ] 2.2 Migration `units` (id uuid, condominium_id FK, building_id FK, identification, timestamps)
- [ ] 2.3 Migration `people` (id uuid, condominium_id FK, user_id FK nullable, name, cpf, type enum, pending_invitation_id nullable, timestamps; índice único em `(condominium_id, cpf)`)
- [ ] 2.4 Migration `occupancies` (id uuid, condominium_id FK, unit_id FK, person_id FK, owner boolean default false, responsible boolean default false, start_date, end_date nullable, timestamps)
- [ ] 2.5 Índices parciais únicos: `occupancies` com no máx. 1 linha `owner: true` ativa por `unit_id`, no máx. 1 linha `responsible: true` ativa por `unit_id` (considerar `unique index ... where (owner = true AND end_date IS NULL)`, idem para `responsible`)
- [ ] 2.6 Rodar migrations em development e test

## 3. Building

- [ ] 3.1 Model `Registry::Building` — `belongs_to :condominium`, validação de `name`
- [ ] 3.2 Factory + testes de invariante (Building sem Condominium é rejeitado)

## 4. Unit

- [ ] 4.1 Model `Registry::Unit` — `belongs_to :building`, `condominium_id` denormalizado e validado consistente com o `Building`
- [ ] 4.2 Factory + testes de invariante (Unit sem Building é rejeitado)

## 5. Person

- [ ] 5.1 Model `Registry::Person` — `belongs_to :condominium`, `belongs_to :user, optional: true`, enum `type: resident | service_provider`, validação de CPF (formato/dígito verificador)
- [ ] 5.2 Unicidade `(condominium_id, cpf)`
- [ ] 5.3 Factory + testes: CPF duplicado no mesmo condomínio não cria Person nova; CPF duplicado em condomínios diferentes cria Person distintas

## 6. Occupancy

- [ ] 6.1 Model `Registry::Occupancy` — `belongs_to :unit`, `belongs_to :person`, `condominium_id` denormalizado, flags `owner`/`responsible`
- [ ] 6.2 Validação: `owner` e `responsible` nunca `true` simultaneamente na mesma Occupancy
- [ ] 6.3 Validação/constraint: no máx. 1 `owner` ativo por Unit, no máx. 1 `responsible` ativo por Unit (nível de aplicação + índice parcial do banco, defesa em profundidade — mesmo padrão de `add-tenancy`)
- [ ] 6.4 Método pra encerrar (`end_date = hoje`) sem apagar o registro (append-only, histórico preservado)
- [ ] 6.5 Factory + testes: segundo owner/responsible ativo rejeitado, mesma Person em várias Unit do mesmo condomínio sem conflito

## 7. Autorização (Pundit)

- [ ] 7.1 Policy que decide quem pode chamar `RegisterOccupant`/`EndOccupancy` pra qual Unit: admin (via `Tenancy::Membership`) pode qualquer Unit; `owner` só a própria Unit (e só define `responsible` ou morador comum); `responsible` só a própria Unit (e só morador comum)
- [ ] 7.2 Regra explícita: encerrar Occupancy de `owner` é admin-only, mesmo o próprio `owner` não pode
- [ ] 7.3 Regra explícita: `responsible` não revoga a si mesmo — só `owner` da Unit revoga/troca `responsible`
- [ ] 7.4 Testes de policy cobrindo os cenários acima

## 8. RegisterOccupant

- [ ] 8.1 Service `Registry::RegisterOccupant(unit:, person_attributes:, owner:, responsible:, grant_access:)` (Dry::Monads::Result) — busca `Person` por CPF no condomínio, reaproveita ou cria; cria `Occupancy`
- [ ] 8.2 Quando `grant_access: true`: chama `Tenancy::InviteMember` (service público, chamada síncrona direta — ver design.md Decisão 6) com o email/role apropriado; guarda o `invitation.id` retornado em `Person.pending_invitation_id`
- [ ] 8.3 Quando `grant_access: false`: nenhum convite é criado
- [ ] 8.4 Factory + testes cobrindo os fluxos mapeados: admin cadastra dono, admin cadastra responsible direto, owner delega responsible, responsible cadastra morador comum — cada um checando a policy do Grupo 7

## 9. RegisterServiceProvider

- [ ] 9.1 Service `Registry::RegisterServiceProvider(person_attributes:, grant_access:)` — cria `Person(type: service_provider)`, sem `Unit`/`Occupancy`
- [ ] 9.2 Testes: prestador nunca gera Occupancy; concessão de acesso opcional segue o mesmo caminho do Grupo 8.2

## 10. EndOccupancy

- [ ] 10.1 Service `Registry::EndOccupancy(occupancy:)` — encerra (`end_date`), respeitando a policy do Grupo 7
- [ ] 10.2 Testes: admin encerra owner; owner encerra responsible; responsible/owner/admin encerram morador comum; cada violação de hierarquia rejeitada

## 11. Integração com Tenancy — evento de aceite de convite

- [ ] 11.1 Em `Tenancy::AcceptInvitation` (change `add-tenancy`, já implementada): publicar evento de domínio (`Tenancy::InvitationAccepted` ou mecanismo equivalente já usado no projeto) com `invitation_id` e `user_id`, sem qualquer referência a `Registry`
- [ ] 11.2 Testes em `Tenancy` confirmando que o evento é publicado no aceite, e que `Tenancy` não referencia `Registry` em nenhum ponto do código
- [ ] 11.3 Em `Registry`: assinante do evento que busca `Person` por `pending_invitation_id == invitation_id` e preenche `Person.user_id`, limpando `pending_invitation_id`
- [ ] 11.4 Testes: aceite de convite de uma Person cadastrada por `RegisterOccupant`/`RegisterServiceProvider` preenche `user_id` corretamente; evento de um convite não relacionado a nenhuma Person (fluxo de staff do Tenancy) não afeta nada em Registry

## 12. Rotas e serializers

- [ ] 12.1 Rotas em inglês sob `/api/v1/`: cadastro de ocupante numa unidade, cadastro de prestador, encerramento de ocupação
- [ ] 12.2 Serializers (`jsonapi-serializer`) para `Building`, `Unit`, `Person`, `Occupancy`

## 13. Validação final

- [ ] 13.1 `bundle exec rspec` roda sem falhas
- [ ] 13.2 `docker compose up`/`restart` sobe sem erro com as novas migrations aplicadas
- [ ] 13.3 Fluxo manual de ponta a ponta: admin cadastra dono com acesso → dono loga → dono delega responsible → responsible cadastra morador comum → aceite de convite reconcilia `Person.user_id` corretamente (não por email)
- [ ] 13.4 Atualizar `CLAUDE.md` se necessário (mesmo padrão de módulos já documentado em `add-tenancy` deve cobrir Registry sem mudança adicional — só confirmar)
