## 1. Ponto de restauração (opcional, decidir com o usuário)

- [x] 1.1 Confirmar com o usuário se um commit "snapshot do esqueleto CredFlow" deve ser feito antes de iniciar a remoção (ver Open Question em `design.md`) — usuário confirmou que já fez esse commit manualmente antes do `/opsx:apply`
- [x] 1.2 Se confirmado, criar esse commit isolado antes de qualquer outra task deste change — já existia (`068bcc6`) antes do início da implementação

## 2. Renomear o serviço base

- [x] 2.1 `git mv services/account-service services/neighbry-api`
- [x] 2.2 Ajustar nome da aplicação Rails (`config/application.rb`, `Gemfile` se referenciar o nome) e quaisquer strings/paths que referenciem `account-service` internamente (Dockerfile, README do serviço se existir) — módulo `AccountService` → `NeighbryApi`; `db/seeds.rb` também reescrito (referenciava models removidos e e-mails `@credflow.com`)
- [x] 2.3 Corrigir permissões de arquivo pós-rename se necessário (`chown` conforme convenção do `CLAUDE.md`)

## 3. Remover serviços descartados

- [x] 3.1 Remover `services/payment-service/`
- [x] 3.2 Remover `services/receivables-service/`
- [x] 3.3 Remover `mocks/spb-mock/`, `mocks/kyc-mock/`, `mocks/boleto-mock/`
- [x] 3.4 Remover `api-gateway/`

## 4. Remover RabbitMQ do `neighbry-api`

- [x] 4.1 Remover `app/consumers/` (todos os consumers herdados)
- [x] 4.2 Remover `app/publishers/event_publisher.rb`
- [x] 4.3 Remover `config/initializers/rabbitmq.rb`
- [x] 4.4 Remover gems `bunny` e `sneakers` do `Gemfile` e rodar `bundle install` — também removidos `config/sneakers.rb` (não estava listado na proposta original) e `app/mailers/` + views (NotificationMailer só existia para os consumers removidos); gem `faraday` também removida por ficar sem uso (só existia para chamar o kyc-mock)

## 5. Trocar Solid Queue por Sidekiq

- [x] 5.1 Remover gem `solid_queue` do `Gemfile`; adicionar gem `sidekiq`
- [x] 5.2 Remover configuração/initializers de Solid Queue (plugin `:solid_queue` no `config/puma.rb`) e adicionar `config/initializers/sidekiq.rb` apontando para o `redis` do compose; `config.active_job.queue_adapter = :sidekiq` em `application.rb`
- [x] 5.3 Rodar `bundle install`

## 6. Remover models e infraestrutura de domínio do CredFlow

- [x] 6.1 Remover model `Participant` (model, migration, spec, factory)
- [x] 6.2 Remover model `Account` (model, migration, spec, factory)
- [x] 6.3 Remover model `LedgerEntry` (model, migration, spec, factory)
- [x] 6.4 Remover `app/controllers/internal/e2e_controller.rb` e as rotas `/internal/e2e/seed` em `config/routes.rb` — também `lib/tasks/seed_e2e.rake`, achado durante validação (referenciava os models removidos)
- [x] 6.5 Remover controllers/serializers/rotas associados a `participants`, `accounts`, `ledger_entries` em `config/routes.rb` — todo `app/controllers/internal/` e `app/controllers/api/v1/{base,accounts,participants,ledger_entries}_controller.rb` removidos; `app/services/*` (kyc_check, ledger_writer, open_account, balance_calculator) e `app/serializers/*` também removidos por dependerem exclusivamente desses models
- [x] 6.6 Confirmar que `User`, `JwtDenylist` e a configuração Devise/devise-jwt permanecem intactos — confirmado; corrigido bug pré-existente descoberto na validação (ver task 10.3)
- [x] 6.7 Rodar migrations para refletir a remoção dos models antigos (ambiente development e test) — `db/schema.rb` também precisou ser apagado e regenerado (Rails 8 carrega o schema.rb automaticamente quando `schema_migrations` não existe, e o arquivo antigo ainda declarava as tabelas do CredFlow)

## 7. Atualizar `docker-compose.yml`

- [x] 7.1 Consolidar para um único serviço Postgres (remover `postgres-payment`, `postgres-receivables`)
- [x] 7.2 Remover serviço `rabbitmq` e os serviços de consumer dedicados (`account-consumer`, `receivables-consumer`)
- [x] 7.3 Remover serviços `payment-jobs`, `receivables-jobs`; adicionar serviço `sidekiq` dependente de `redis` e `postgres`
- [x] 7.4 Remover serviços `spb-mock`, `kyc-mock`, `boleto-mock`
- [x] 7.5 Remover serviço `api-gateway` (Nginx)
- [x] 7.6 Remover serviço `mailhog`
- [x] 7.7 Renomear serviço `account-service` para `neighbry-api` no compose (build context, porta exposta)
- [x] 7.8 Remover `docker-compose.e2e.yml`
- Nota: portas de host do `postgres` (5442) e `redis` (6389) usam mapeamento não-padrão porque as portas 5432/6379 já estavam ocupadas por outro projeto (`lago_db_dev`/`lago_redis_dev`) na máquina de desenvolvimento; a rede interna do Docker continua em 5432/6379.

## 8. Atualizar frontend

- [x] 8.1 Atualizar `frontend/src/lib/api.ts` — `baseURL` aponta direto para `neighbry-api` (porta do serviço renomeado) em vez do gateway — default `http://localhost:3001`; tokens/persist keys renomeados de `credflow_*` para `neighbry_*`
- [x] 8.2 Remover `frontend/playwright.config.ts` e todos os arquivos `*.e2e.ts` — removido `src/e2e/` inteiro (incluía `global-setup.ts`)
- [x] 8.3 Remover dependência `@playwright/test` do `package.json` (se listada) e rodar `npm install`
- [x] 8.4 Decisão registrada: código de domínio CredFlow no frontend (`features/accounts`, `participants`, `payments`, `receivables`, `monitoring` + rotas associadas + testes em `src/test/pages/`) foi **removido nesta mesma change**, não adiado — mantinha imports/rotas para endpoints que não existem mais no backend (quebraria o build). Mantido: `features/auth` (login/registro), layout (`Sidebar`/`AppLayout`, simplificado — sem nav de domínio, sem wordmark CredFlow), `lib/`, `store/authStore`. Branding trocado de CredFlow → Neighbry (título, favicon, textos, chaves de localStorage).

## 9. Revisar documentação

- [x] 9.1 Remover `docs/techs.md`, `docs/features.md`, `docs/data-model.md`, `docs/rabbitmq.md`, `docs/design-system.md`, `docs/qa-2026-05-24.md`, `docs/mock-interface.png` — `docs/domain.md` também removido (mesma categoria, tinha ficado fora da lista original por engano; confirmado com o usuário antes de remover)
- [x] 9.2 Atualizar `CLAUDE.md` — estrutura de diretórios, portas, comandos, gotchas — para refletir `neighbry-api` único, sem RabbitMQ/Sneakers, sem gateway, sem Playwright/Mailhog — reescrito por completo; seções de domínio/backlog do CredFlow (100% inaplicáveis ao Neighbry) removidas por não terem equivalente ainda, conforme diretriz da seção 0 do `project.md` sobre limpeza oportunista de resíduo de domínio
- [x] 9.3 Confirmar que `openspec/project.md` já reflete a arquitetura alvo (não deve precisar de mudança nesta task) — confirmado, nenhuma mudança necessária

## 10. Validação final

- [x] 10.1 `docker compose build` e `docker compose up` sobem sem erro
- [x] 10.2 `neighbry-api` responde em `GET /up` (health check) — HTTP 200
- [x] 10.3 Endpoints Devise (`sign_up`, `sign_in`, `sign_out`) respondem corretamente — `sign_up` estava quebrado por bug pré-existente do esqueleto herdado (app `--api` sem middleware de sessão; Devise/Warden precisa dele mesmo com JWT). Corrigido em `config/application.rb` (`ActionDispatch::Cookies` + `ActionDispatch::Session::CookieStore`). Não era causado por nenhuma mudança desta change, mas bloqueava a própria validação desta task
- [x] 10.4 `bundle exec rspec` roda sem falhas (specs remanescentes, sem referência a models removidos) — 4/4 exemplos passando
- [x] 10.5 `docker compose config` não lista `rabbitmq`, `mailhog`, `api-gateway`, `spb-mock`, `kyc-mock`, `boleto-mock`, `payment-service`, `receivables-service`, `postgres-payment`, `postgres-receivables` — confirmado
- [x] 10.6 Frontend sobe e faz ao menos uma chamada HTTP de smoke test direto para `neighbry-api` sem gateway — build de produção (`tsc -b && vite build`) limpo, 27/27 testes Vitest passando (2 falhas encontradas e corrigidas: testes tinham `localhost:8080` do gateway antigo hardcoded como base URL do mock MSW), `curl` em `localhost:5173` retorna 200
