## Why

O projeto foi inicializado copiando o esqueleto de um projeto Rails anterior (CredFlow — 3 microsserviços com RabbitMQ, mocks Sinatra, gateway Nginx, Playwright E2E e Mailhog) para pular o setup repetitivo. Neighbry é um domínio e uma arquitetura diferentes: um **Rails Modular Monolith** de serviço único, sem mensageria entre serviços, com mocks internos e sem gateway. Antes de implementar qualquer bounded context do Neighbry (Registry, Billing, Notice, Access, CommonArea), o esqueleto herdado precisa ser reduzido à base real da nova arquitetura — caso contrário cada feature futura carrega peças mortas (filas, consumers, serviços duplicados, documentação de outro domínio) que confundem mais do que ajudam.

## What Changes

- Renomear `services/account-service` para `services/neighbry-api` — vira o único backend Rails do monolito.
- **BREAKING**: Descartar `services/payment-service` e `services/receivables-service` por completo.
- **BREAKING**: Remover RabbitMQ (Bunny + Sneakers): `app/consumers/`, `app/publishers/event_publisher.rb`, `config/initializers/rabbitmq.rb`, gems `bunny`/`sneakers`, serviço `rabbitmq` e consumers dedicados no `docker-compose.yml`.
- Trocar `solid_queue` por `sidekiq` como backend de jobs assíncronos/cron (gem no `Gemfile`, serviço `sidekiq` no `docker-compose.yml` substituindo `payment-jobs`/`receivables-jobs`).
- Converter os mocks externos (KYC, SPB, boleto) de microsserviços Sinatra (`mocks/kyc-mock`, `mocks/spb-mock`, `mocks/boleto-mock`) em service objects internos ao `neighbry-api`; remover os processos Sinatra e suas entradas no `docker-compose.yml`.
- **BREAKING**: Remover o `api-gateway` Nginx — o frontend passa a chamar `neighbry-api` diretamente, sem proxy reverso por prefixo de rota.
- Remover Mailhog e toda infraestrutura de envio de e-mail (fica registrado como requisito futuro, fora de escopo agora).
- Remover a suíte E2E Playwright: `docker-compose.e2e.yml`, `frontend/playwright.config.ts`, testes `*.e2e.ts`, `app/controllers/internal/e2e_controller.rb` e rotas `/internal/e2e/seed`.
- Remover os models de domínio do CredFlow (`Participant`, `Account`, `LedgerEntry`) e suas migrations/specs associadas; manter a infraestrutura de autenticação (Devise + devise-jwt, `User`, `JwtDenylist`) por ser reaproveitável.
- Atualizar `docker-compose.yml` para a nova topologia: um Postgres único, Redis, `neighbry-api`, `sidekiq`, `frontend` — sem RabbitMQ, mocks externos, gateway ou Mailhog.
- Atualizar `frontend/src/lib/api.ts` para apontar `baseURL` direto para `neighbry-api` (em vez do gateway em `localhost:8080`).
- Revisar a documentação herdada em `docs/`: descartar ou reescrever o que é específico do domínio/arquitetura do CredFlow (`techs.md`, `features.md`, `data-model.md`, `rabbitmq.md`, `design-system.md`, `qa-2026-05-24.md`, `mock-interface.png`).
- Atualizar `CLAUDE.md` para refletir a nova estrutura de diretórios, portas e comandos (hoje ainda documenta os 3 serviços, RabbitMQ e Playwright do CredFlow).

## Capabilities

### New Capabilities
- `local-dev-environment`: topologia de infraestrutura local do monolito Neighbry (docker-compose com serviço Rails único, Postgres único, Redis, Sidekiq, frontend — sem mensageria entre serviços, sem gateway, sem mocks externos como processos separados).

### Modified Capabilities
(nenhuma — `openspec/specs/` está vazio; não há capabilities de domínio pré-existentes sendo alteradas)

## Impact

- **Código removido**: `services/payment-service/`, `services/receivables-service/`, `mocks/spb-mock/`, `mocks/kyc-mock/`, `mocks/boleto-mock/`, `api-gateway/`, `docker-compose.e2e.yml`, `frontend/playwright.config.ts`, testes `*.e2e.ts`.
- **Código renomeado/reestruturado**: `services/account-service/` → `services/neighbry-api/`; models de domínio antigo removidos; mocks viram service objects internos.
- **Dependências**: `Gemfile` perde `bunny`, `sneakers`, `solid_queue`; ganha `sidekiq`. `package.json` do frontend não muda nas dependências, só `api.ts`.
- **Infraestrutura**: `docker-compose.yml` reduzido de ~17 serviços para 5 (`postgres`, `redis`, `neighbry-api`, `sidekiq`, `frontend`).
- **Documentação**: `docs/*.md` revisados; `CLAUDE.md` atualizado; `openspec/project.md` não muda (já reflete a arquitetura alvo).
- **Sem impacto em produção**: projeto ainda não tem nenhum commit — esta é a mudança fundacional antes do primeiro commit real.
