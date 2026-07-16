# Neighbry

Sistema de gestão condominial desenvolvido como projeto de aprendizado, com foco em **DDD (Domain-Driven Design)** e conceitos de **DDIA (Designing Data-Intensive Applications)**.

Administração de condomínios com múltiplas torres, cobrança de taxas rateadas por metragem de unidade, comunicação síndico↔morador, e controle de acesso (com reconhecimento facial mockado).

Ver `openspec/project.md` para a especificação completa do domínio (bounded contexts, aggregates, invariantes, fluxos principais).

---

## Arquitetura

Rails Modular Monolith: um único backend (`neighbry-api`), organizado internamente em módulos com fronteiras explícitas por bounded context — sem serviços separados, comunicação entre módulos via Domain Events publicados internamente.

Bounded contexts planejados: **Registry** (torres, unidades, pessoas), **Billing** (taxas, rateio, faturas, pagamentos), **Notice** (avisos e confirmação de leitura), **Access** (entrada/saída, reconhecimento facial mock), **CommonArea** (cadastro de espaços comuns).

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
├── services/
│   └── neighbry-api/    # backend Rails único (monolito modular)
├── frontend/             # React 19 + Vite 6 SPA
└── openspec/             # planejamento de mudanças e especificação do domínio
```

---

## Status atual

Projeto em fase inicial: infraestrutura base migrada de um esqueleto anterior para a arquitetura de monolito descrita acima (auth via Devise/JWT funcional). Nenhum bounded context de domínio foi implementado ainda — acompanhar `openspec/changes/` para o histórico de mudanças em andamento.
