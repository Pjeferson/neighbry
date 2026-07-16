## Context

O repositório foi criado copiando o esqueleto do CredFlow, um projeto anterior de portfólio com arquitetura de 3 microsserviços Rails (`account-service`, `payment-service`, `receivables-service`), comunicação assíncrona via RabbitMQ, 3 mocks Sinatra simulando integrações externas (KYC, SPB, boleto), gateway Nginx multi-upstream, testes E2E via Playwright contra Docker Compose e Mailhog para inspeção de e-mails.

Nenhum commit foi feito ainda neste repositório — o código em `services/`, `mocks/`, `api-gateway/` e `docker-compose.yml` é 100% herdado do CredFlow. `openspec/project.md` já descreve a arquitetura alvo do Neighbry (Rails Modular Monolith, um serviço só, eventos de domínio internos, Sidekiq, sem gateway). Esta mudança fecha a lacuna entre o que está no disco e o que `project.md` descreve, sem introduzir nenhuma feature de domínio do Neighbry (Registry/Billing/Notice/Access/CommonArea) — isso é sequenciado nos changes seguintes.

## Goals / Non-Goals

**Goals:**
- Reduzir o esqueleto a um único serviço Rails (`neighbry-api`) rodando como monolito modular.
- Eliminar toda infraestrutura de comunicação entre serviços (RabbitMQ/Bunny/Sneakers) que não tem mais razão de existir com um serviço só.
- Substituir os mocks externos (processos Sinatra) por service objects internos, já que não há mais fronteira de processo a simular.
- Deixar `docker-compose.yml` e `CLAUDE.md` consistentes com a topologia real do projeto.
- Remover código, testes e documentação específicos do domínio CredFlow que não fazem sentido carregar adiante.
- Preservar a infraestrutura genuinamente reaproveitável: Devise/devise-jwt, Pundit, dry-monads, jsonapi-serializer, rack-cors, RSpec/FactoryBot/Faker/Shoulda, o scaffold do frontend (Vite/TanStack/shadcn).

**Non-Goals:**
- Não implementa nenhum model, controller ou spec de domínio do Neighbry (Registry, Billing, Notice, Access, CommonArea) — isso é escopo dos changes seguintes.
- Não define a estrutura de pastas dos módulos (`app/domains/registry`, etc.) nem escolhe a gem de eventos de domínio (`wisper` vs `dry-events`) — fica para o change que introduzir o primeiro bounded context, quando houver um caso de uso real para validar a escolha.
- Não reintroduz e-mail, Playwright E2E ou gateway — ficam registrados como possíveis requisitos futuros, não implementados aqui.

## Decisions

**1. `account-service` vira `neighbry-api`, os outros dois serviços são descartados.**
Alternativa considerada: criar um app Rails novo do zero e portar só o que interessa. Rejeitada porque `account-service` já tem Devise/devise-jwt funcionando (o pedaço mais chato de configurar em modo API), RSpec/FactoryBot configurados e a estrutura de pastas (`app/services`, `app/serializers`, `app/policies`) que `CLAUDE.md` já documenta como convenção. Renomear é mais barato que reconfigurar auth do zero.

**2. RabbitMQ sai; comunicação entre módulos vira chamada Ruby direta (ou publish/subscribe in-process no futuro).**
Com um serviço só, não há mais fronteira de rede a atravessar — `EventPublisher`/`ApplicationConsumer` resolviam um problema (comunicação assíncrona entre processos) que deixou de existir. `project.md` já aponta `wisper`/`dry-events` como opção para eventos de domínio internos, mas a escolha da gem fica para quando houver um evento de domínio real para modelar (ex: `FaturaPaga`), não neste change de infraestrutura.

**3. Solid Queue → Sidekiq.**
`project.md` (seção 6) especifica Sidekiq explicitamente. Trade-off: Solid Queue não precisa de Redis extra (persiste no Postgres do próprio serviço), mas o Redis já está no compose por outro motivo previsto em `project.md` (cache), então a vantagem de "sem infra extra" do Solid Queue não se aplica aqui. Seguimos a decisão já registrada em `project.md`.

**4. Mocks externos (KYC, SPB, boleto) viram service objects dentro do `neighbry-api`, não processos HTTP separados.**
Os mocks simulavam integrações com sistemas externos reais (SPB, birô de KYC) num contexto onde `payment-service`/`receivables-service` precisavam demonstrar chamada HTTP entre serviços. No monolito, reconhecimento facial mock e boleto/PIX fake são comportamento interno de módulos (`Access`, `Billing`) — não há processo externo real a simular ainda. Se no futuro fizer sentido treinar o padrão de integração HTTP com parceiro externo, isso volta como decisão explícita, não por herança do esqueleto antigo.

**5. Gateway Nginx removido; frontend fala direto com `neighbry-api`.**
Com um único backend, o gateway não resolve roteamento (não há múltiplos upstreams pra unificar). `frontend/src/lib/api.ts` muda `baseURL` de `http://localhost:8080` para a porta do `neighbry-api` (mantém 3001, já usada pelo `account-service` hoje, para minimizar mudança).

**6. Playwright E2E e Mailhog removidos, não apenas desativados.**
Ambos foram tentados no CredFlow e o usuário relatou que o E2E teve custo alto para o retorno nesse estágio do projeto. Remover (não comentar/flag) evita manutenção de código morto; reintroduzir Playwright ou e-mail transacional é um change futuro explícito quando houver necessidade real.

**7. Documentação herdada (`docs/*.md`) é descartada, não editada incrementalmente.**
`techs.md` e `features.md` descrevem quase inteiramente comportamento e arquitetura do CredFlow que estão sendo removidos neste mesmo change (RabbitMQ, AASM em `PaymentOrder`, 3 bancos, Playwright, gateway) — uma edição incremental deixaria o arquivo entrelaçando o que ficou com o que saiu. `data-model.md` e `rabbitmq.md` descrevem schema e topologia que deixam de existir. `design-system.md` documenta uma identidade visual que nunca foi definida para o Neighbry. `qa-2026-05-24.md` é um log de sessão de QA específico do CredFlow. `mock-interface.png` é screenshot da UI antiga. Novos docs equivalentes para o Neighbry (se necessários) nascem junto com as features de domínio que descrevem, não antecipadamente vazios.

## Risks / Trade-offs

- **[Risco] Descartar `payment-service`/`receivables-service` apaga código de referência (AASM, policy engine, idempotência via Redis) que poderia ser consultado como exemplo ao implementar Billing.**
  → Mitigação: o histórico permanece acessível via `git log`/tags se algum dia for necessário consultar; como não há commit ainda, considerar um commit inicial "snapshot do esqueleto CredFlow" antes de iniciar a remoção, só para preservar a referência no histórico do Git sem manter o código no working tree.
- **[Risco] Sidekiq exige Redis já disponível; se o Redis do compose for removido por engano (já que a única consumidora hoje, idempotência, também está sendo removida), Sidekiq quebra.**
  → Mitigação: manter `redis` explicitamente no `docker-compose.yml` como dependência do `sidekiq`, documentar isso no `tasks.md`.
- **[Risco] Remover o `api_gateway`/Nginx sem atualizar `CLAUDE.md` e `frontend/api.ts` na mesma mudança deixa o projeto num estado inconsistente (frontend não conecta em nada).**
  → Mitigação: tratar como uma unidade — task única que remove o gateway, atualiza `docker-compose.yml`, `nginx` removido, e `api.ts` no mesmo commit.

## Migration Plan

1. Commit "snapshot" opcional do estado atual do esqueleto (ver risco acima), antes de qualquer remoção — só se o usuário confirmar que quer esse ponto de restauração no histórico.
2. Renomear `services/account-service` → `services/neighbry-api` (git mv), ajustar nome da app Rails/módulo interno se necessário.
3. Remover `services/payment-service/`, `services/receivables-service/`, `mocks/*/`, `api-gateway/`.
4. Dentro de `neighbry-api`: remover consumers/publishers/initializer de RabbitMQ, gems `bunny`/`sneakers`; remover models `Participant`/`Account`/`LedgerEntry` e migrations associadas; remover `e2e_controller` e rotas `/internal/e2e/seed`.
5. Trocar `solid_queue` por `sidekiq` no `Gemfile` e configuração.
6. Atualizar `docker-compose.yml` e remover `docker-compose.e2e.yml`.
7. Atualizar `frontend/src/lib/api.ts` (baseURL) e remover `playwright.config.ts` + testes `*.e2e.ts`.
8. Revisar `docs/*.md` (descartar os listados) e atualizar `CLAUDE.md`.
9. Rodar `bundle install`, subir `docker compose up` e validar que o serviço sobe, migra e responde no endpoint `up` de health check.

Sem estratégia de rollback formal além do Git — não há ambiente implantado, o projeto ainda não tem commits.

## Open Questions

- Vale registrar um commit "snapshot" do esqueleto CredFlow antes de começar a remoção, só para preservar referência no histórico? (mitigação do primeiro risco acima — decisão do usuário, não bloqueia o restante do change).
