## 1. Ponto de restauração (opcional, decidir com o usuário)

- [ ] 1.1 Confirmar com o usuário se um commit "snapshot do esqueleto CredFlow" deve ser feito antes de iniciar a remoção (ver Open Question em `design.md`)
- [ ] 1.2 Se confirmado, criar esse commit isolado antes de qualquer outra task deste change

## 2. Renomear o serviço base

- [ ] 2.1 `git mv services/account-service services/neighbry-api`
- [ ] 2.2 Ajustar nome da aplicação Rails (`config/application.rb`, `Gemfile` se referenciar o nome) e quaisquer strings/paths que referenciem `account-service` internamente (Dockerfile, README do serviço se existir)
- [ ] 2.3 Corrigir permissões de arquivo pós-rename se necessário (`chown` conforme convenção do `CLAUDE.md`)

## 3. Remover serviços descartados

- [ ] 3.1 Remover `services/payment-service/`
- [ ] 3.2 Remover `services/receivables-service/`
- [ ] 3.3 Remover `mocks/spb-mock/`, `mocks/kyc-mock/`, `mocks/boleto-mock/`
- [ ] 3.4 Remover `api-gateway/`

## 4. Remover RabbitMQ do `neighbry-api`

- [ ] 4.1 Remover `app/consumers/` (todos os consumers herdados)
- [ ] 4.2 Remover `app/publishers/event_publisher.rb`
- [ ] 4.3 Remover `config/initializers/rabbitmq.rb`
- [ ] 4.4 Remover gems `bunny` e `sneakers` do `Gemfile` e rodar `bundle install`

## 5. Trocar Solid Queue por Sidekiq

- [ ] 5.1 Remover gem `solid_queue` do `Gemfile`; adicionar gem `sidekiq`
- [ ] 5.2 Remover configuração/initializers de Solid Queue (`config/recurring.yml`, `config/queue.yml` se existirem) e adicionar `config/initializers/sidekiq.rb` apontando para o `redis` do compose
- [ ] 5.3 Rodar `bundle install`

## 6. Remover models e infraestrutura de domínio do CredFlow

- [ ] 6.1 Remover model `Participant` (model, migration, spec, factory)
- [ ] 6.2 Remover model `Account` (model, migration, spec, factory)
- [ ] 6.3 Remover model `LedgerEntry` (model, migration, spec, factory)
- [ ] 6.4 Remover `app/controllers/internal/e2e_controller.rb` e as rotas `/internal/e2e/seed` em `config/routes.rb`
- [ ] 6.5 Remover controllers/serializers/rotas associados a `participants`, `accounts`, `ledger_entries` em `config/routes.rb`
- [ ] 6.6 Confirmar que `User`, `JwtDenylist` e a configuração Devise/devise-jwt permanecem intactos
- [ ] 6.7 Rodar migrations para refletir a remoção dos models antigos (ambiente development e test)

## 7. Atualizar `docker-compose.yml`

- [ ] 7.1 Consolidar para um único serviço Postgres (remover `postgres-payment`, `postgres-receivables`)
- [ ] 7.2 Remover serviço `rabbitmq` e os serviços de consumer dedicados (`account-consumer`, `receivables-consumer`)
- [ ] 7.3 Remover serviços `payment-jobs`, `receivables-jobs`; adicionar serviço `sidekiq` dependente de `redis` e `postgres`
- [ ] 7.4 Remover serviços `spb-mock`, `kyc-mock`, `boleto-mock`
- [ ] 7.5 Remover serviço `api-gateway` (Nginx)
- [ ] 7.6 Remover serviço `mailhog`
- [ ] 7.7 Renomear serviço `account-service` para `neighbry-api` no compose (build context, porta exposta)
- [ ] 7.8 Remover `docker-compose.e2e.yml`

## 8. Atualizar frontend

- [ ] 8.1 Atualizar `frontend/src/lib/api.ts` — `baseURL` aponta direto para `neighbry-api` (porta do serviço renomeado) em vez do gateway
- [ ] 8.2 Remover `frontend/playwright.config.ts` e todos os arquivos `*.e2e.ts`
- [ ] 8.3 Remover dependência `@playwright/test` do `package.json` (se listada) e rodar `npm install`
- [ ] 8.4 Verificar se `frontend/src/features/` tem código específico do domínio CredFlow (participants, accounts, ledger, payment orders, ccbs) que deve ser removido nesta task ou fica marcado para remoção no change que introduzir o primeiro bounded context do Neighbry — decidir e registrar a decisão

## 9. Revisar documentação

- [ ] 9.1 Remover `docs/techs.md`, `docs/features.md`, `docs/data-model.md`, `docs/rabbitmq.md`, `docs/design-system.md`, `docs/qa-2026-05-24.md`, `docs/mock-interface.png`
- [ ] 9.2 Atualizar `CLAUDE.md` — estrutura de diretórios, portas, comandos, gotchas — para refletir `neighbry-api` único, sem RabbitMQ/Sneakers, sem gateway, sem Playwright/Mailhog
- [ ] 9.3 Confirmar que `openspec/project.md` já reflete a arquitetura alvo (não deve precisar de mudança nesta task)

## 10. Validação final

- [ ] 10.1 `docker compose build` e `docker compose up` sobem sem erro
- [ ] 10.2 `neighbry-api` responde em `GET /up` (health check)
- [ ] 10.3 Endpoints Devise (`sign_up`, `sign_in`, `sign_out`) respondem corretamente
- [ ] 10.4 `bundle exec rspec` roda sem falhas (specs remanescentes, sem referência a models removidos)
- [ ] 10.5 `docker compose config` não lista `rabbitmq`, `mailhog`, `api-gateway`, `spb-mock`, `kyc-mock`, `boleto-mock`, `payment-service`, `receivables-service`, `postgres-payment`, `postgres-receivables`
- [ ] 10.6 Frontend sobe e faz ao menos uma chamada HTTP de smoke test direto para `neighbry-api` sem gateway
