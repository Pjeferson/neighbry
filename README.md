# Neighbry

Sistema de gestão condominial construído como projeto de aprendizado — a meta não é entregar um produto, é praticar **DDD (Domain-Driven Design)** e conceitos de **DDIA (Designing Data-Intensive Applications)** num contexto realista, com um domínio rico o suficiente pra render decisões de modelagem de verdade.

A ideia central: administração de condomínios com múltiplas torres, cobrança de taxas rateadas, comunicação síndico↔morador e cadastro de espaços comuns — modelado como um **Rails Modular Monolith**, onde cada bounded context vive isolado por namespace Ruby e só se comunica com os outros via Domain Events ou leitura direta (nunca escrita) entre módulos. É a mesma fronteira que existiria se, um dia, algum desses módulos virasse um serviço separado.

Ver `openspec/project.md` para a especificação completa do domínio (bounded contexts, aggregates, invariantes, fluxos principais) e `openspec/specs/` para o comportamento formal, requirement por requirement, de cada capability já implementada.

---

## O que já existe

Cinco bounded contexts implementados, testados e arquivados no OpenSpec (histórico completo de cada um em `openspec/changes/archive/`):

| Bounded Context | O que faz |
|---|---|
| **Tenancy** | Multi-tenancy por subdomínio, convite/aceite de acesso, papéis (admin/manager/doorman/resident) |
| **Registry** | Torres, unidades, pessoas e ocupações — hierarquia de autoridade (admin > proprietário > responsável > morador) |
| **Billing** | Taxas, geração mensal idempotente de cobrança, pagamento manual ou via simulação de webhook de PSP |
| **Notice** | Avisos direcionados (condomínio inteiro, moradores, staff, uma torre ou uma unidade) com confirmação de leitura |
| **CommonArea** | Catálogo de espaços comuns do condomínio |

**Access** (controle de entrada/saída com reconhecimento facial mockado) foi deliberadamente adiado para uma v2 — está documentado em `openspec/project.md`, mas fora do escopo atual.

### Alguns destaques técnicos

- **Domain Events entre módulos**: `Tenancy` publica eventos de onboarding/convite sem saber quem escuta; `Registry` e `Billing` reagem a eles de forma totalmente desacoplada.
- **Geração de cobrança mensal idempotente e retomável**: o job pode rodar mais de uma vez, cair no meio, e retomar de onde parou sem duplicar nada — só com índices únicos e um status de ciclo, sem lock distribuído.
- **Simulação de PSP com round-trip HTTP real**: em vez de uma chamada Ruby direta, o "pagamento simulado" faz uma requisição HTTP de verdade pro endpoint de webhook — o mesmo que existiria em produção com um PSP real, autenticado por segredo estático em vez de sessão de usuário.
- **Fluxo de exploração → proposta → implementação → arquivamento** via [OpenSpec](https://github.com/anthropics/openspec), com specs formais (`SHALL`/cenários `WHEN`/`THEN`) por capability, validadas antes de cada change ser arquivada.

---

## Arquitetura

Rails Modular Monolith: um único backend (`neighbry-api`), organizado internamente em módulos com fronteiras explícitas por bounded context — sem serviços separados, comunicação entre módulos via Domain Events publicados internamente (`ActiveSupport::Notifications`) ou leitura direta e pontual do model de outro módulo (nunca escrita).

---

## Stack

| Camada       | Tecnologia                    |
|--------------|-------------------------------|
| Runtime      | Ruby 3.4                      |
| Framework    | Rails 8.1 (API-only)          |
| Auth         | Devise + devise-jwt           |
| Banco        | PostgreSQL 17                 |
| Cache/Jobs   | Redis 7 + Sidekiq              |
| Frontend     | React 19 + Vite 6             |
| UI           | shadcn/ui + Tailwind          |
| Testes BE    | RSpec + FactoryBot            |
| Testes FE    | Vitest + Testing Library      |
| Infra local  | Docker Compose                |

---

## Rodando localmente

**Pré-requisito:** Docker e Docker Compose instalados.

```bash
docker compose up
```

Em outro terminal, na primeira vez:

```bash
docker compose run --rm neighbry-api bundle exec rails db:migrate
docker compose run --rm neighbry-api bundle exec rails db:seed
```

| Interface     | URL                    |
|---------------|-------------------------|
| Frontend      | http://localhost:5173  |
| neighbry-api  | http://localhost:3001  |

Ver `CLAUDE.md` para o guia completo de comandos, convenções e gotchas de desenvolvimento.

---

## Estrutura do repositório

```
neighbry/
├── CLAUDE.md
├── docker-compose.yml
├── neighbry-api/          # backend Rails único (monolito modular)
├── neighbry-frontend/     # React 19 + Vite 6 SPA
└── openspec/              # planejamento de mudanças e especificação do domínio
```

---

## Status atual

Backend com cinco bounded contexts implementados e testados (`Tenancy`, `Registry`, `Billing`, `Notice`, `CommonArea`); `Access` fica para v2. Frontend React ainda não foi iniciado — próximo passo natural do projeto. Acompanhe `openspec/changes/archive/` para o histórico completo de cada change já implementada, com proposta, design técnico e especificação formal de cada uma.
