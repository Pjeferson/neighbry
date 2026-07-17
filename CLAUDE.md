# Neighbry

Sistema de gestão condominial desenvolvido como projeto de aprendizado, com foco
em **DDD (Domain-Driven Design)** e conceitos de **DDIA (Designing Data-Intensive
Applications)**. Implementado como **Rails Modular Monolith** + frontend React,
rodando em Docker Compose.

Ver `@openspec/project.md` para a visão completa do domínio (bounded contexts,
aggregates, invariantes, fluxos principais).

---

## Stack

| Camada       | Tecnologia                    |
|--------------|-------------------------------|
| Runtime      | Ruby 3.4                      |
| Framework    | Rails 8.1 (API-only)          |
| Auth         | Devise + devise-jwt           |
| Banco        | PostgreSQL 17                 |
| Cache/Jobs   | Redis 7 + Sidekiq             |
| Frontend     | React 19 + Vite 6             |
| UI           | shadcn/ui + Tailwind          |
| HTTP client  | ky                            |
| Data fetch   | TanStack Query                |
| Routing      | TanStack Router                |
| Testes BE    | RSpec + FactoryBot            |
| Testes FE    | Vitest + Testing Library      |
| Infra local  | Docker Compose                |

---

## Estrutura do monorepo

```
neighbry/
├── CLAUDE.md
├── docker-compose.yml
├── neighbry-api/               # backend Rails único (monolito modular)
├── neighbry-frontend/          # React 19 + Vite 6 SPA
└── openspec/                   # planejamento de mudanças (ver project.md)
```

`neighbry-api` é a única aplicação Rails do projeto. Bounded contexts (Registry,
Billing, Notice, Access, CommonArea) são módulos internos com fronteiras
explícitas (namespaces Ruby), não serviços separados — comunicação entre eles
acontece via Domain Events publicados internamente, nunca por chamada direta
de código de um módulo no modelo de outro. Ver `@openspec/project.md` seção 2.

---

## Portas locais (Docker Compose)

| Serviço          | Porta  |
|------------------|--------|
| neighbry-api        | 3001   |
| neighbry-frontend (Vite) | 5173   |
| postgres         | 5442 (host) → 5432 (container) |
| redis            | 6389 (host) → 6379 (container) |

---

## Ambiente de desenvolvimento

**Ruby e Node.js não estão instalados localmente.** Todo comando que precise de
Ruby ou Node deve rodar via Docker.

### Workflow de gems

```bash
# 1. Adicionar gem ao Gemfile
# 2. Rebuildar a imagem
docker compose build neighbry-api

# 3. Rodar gerador, se necessário
docker compose run --rm neighbry-api bundle exec rails generate <gerador>
```

### Workflow de pacotes npm (neighbry-frontend)

```bash
# 1. Adicionar pacote
docker compose run --rm neighbry-frontend npm install <pacote>

# 2. Rebuildar a imagem
docker compose build neighbry-frontend
```

### Permissões de arquivo

Geradores e `docker compose run` criam arquivos como **root**. Após qualquer
gerador, corrija com:

```bash
docker run --rm -v $(pwd)/neighbry-api:/app ruby:3.4-slim chown -R 1000:1000 /app
```

### Bancos de dados

O `POSTGRES_DB` cria o banco de **development** automaticamente na primeira
inicialização. O banco de **test** não é criado automaticamente:

```bash
docker compose run --rm -e RAILS_ENV=test neighbry-api bundle exec rails db:create db:migrate
```

### Comandos essenciais

```bash
# Subir ambiente completo
docker compose up

# Subir infraestrutura (banco, redis) sem aplicação
docker compose up -d postgres redis

# Console Rails
docker compose run --rm neighbry-api bundle exec rails console

# Migrations
docker compose run --rm neighbry-api bundle exec rails db:migrate

# Testes (RAILS_ENV=test obrigatório)
docker compose run --rm -e RAILS_ENV=test neighbry-api bundle exec rspec

# Logs
docker compose logs -f neighbry-api

# Frontend — testes unitários e de componente (Vitest + MSW)
docker compose run --rm neighbry-frontend npm run test        # modo watch
docker compose run --rm neighbry-frontend npm run test -- --run  # CI / execução única

# Frontend — build de produção
docker compose run --rm neighbry-frontend npm run build
```

### Validações rápidas

```bash
# CORS carregado?
docker compose run --rm neighbry-api bundle exec rails runner \
  "puts Rails.application.config.middleware.middlewares.map { |m| m.klass.to_s }.grep(/Cors/)"

# Serviço conecta ao banco?
docker compose run --rm neighbry-api bundle exec rails db:create

# Sidekiq conecta ao Redis?
docker compose run --rm neighbry-api bundle exec rails runner \
  "puts Sidekiq.redis { |c| c.ping }"
```

### Gotchas importantes

**Devise-jwt em modo API:**
- `respond_to_on_destroy` deve ser sobrescrito com `(**)` para evitar 401 vazio
- `devise_for` deve ficar **fora** de qualquer bloco `namespace` — usar `path: "api/v1/auth"` diretamente
- Revogação de token é responsabilidade do middleware, não do controller
- `SessionsController#create` é **totalmente reescrito** (não usa `warden.authenticate!`/`super`) para checar `Tenancy::Membership` ativo antes de qualquer `sign_in` — isso garante que o JWT nunca é emitido pra um par User+Condominium sem Membership. `sign_out` (`destroy`) usa `skip_before_action :resolve_tenant!` porque logout não depende de subdomínio válido.

**Sidekiq:**
- Roda como processo separado (serviço `sidekiq` no compose), não dentro do Puma
- `config/initializers/sidekiq.rb` aponta para `REDIS_URL`

**Login por subdomínio (Tenancy):**
- Cada `Condominium` é acessado via `<slug>.neighbry.com` em produção; em dev local, `<slug>.localhost:3001` — navegadores modernos resolvem `*.localhost` para `127.0.0.1` automaticamente, sem precisar editar `/etc/hosts`
- `config.action_dispatch.tld_length` é `0` só em `development` (`config/environments/development.rb`) — `localhost` tem 1 label só, diferente de `neighbry.com` (2 labels); sem isso, `request.subdomain` não resolve nada em `acme.localhost`
- Em produção o padrão (`tld_length = 1`) já funciona sem ajuste, porque `neighbry.com` tem a forma normal domínio+TLD

**Testes de frontend:**
- `npm run test` → Vitest (unitários + componente com MSW). Roda isolado, sem stack.
- Não há suíte E2E neste estágio do projeto (Playwright foi avaliado e removido —
  custo alto para o retorno nesta fase; pode ser reintroduzido como decisão
  explícita futura).

**`api.ts` (frontend) — hook de 401:**
- O hook `afterResponse` redireciona para `/login` em qualquer 401, mas endpoints de autenticação (`/auth/sign_in`, `/auth/sign_up`) também retornam 401 em caso de credenciais inválidas.
- Aplicar o redirect apenas quando `!request.url.includes("/auth/")` — caso contrário erros de login causam reload da página e a mensagem de erro nunca é exibida.

---

## Convenções de código — Rails

- **Service objects** em `app/services/` — retornam `Dry::Monads::Result` (Success/Failure)
- **Políticas** em `app/policies/` — Pundit, uma por recurso
- **Serializers** em `app/serializers/` — jsonapi-serializer
- Controllers finos: validação de params → chama service object → serializa → responde
- Toda rota prefixada com `/api/v1/`
- `frozen_string_literal: true` em todos os arquivos Ruby
- Módulos de domínio (bounded contexts) organizados como namespaces explícitos,
  não `app/models` genérico. Padrão em uso desde `add-tenancy` (primeiro
  bounded context implementado — ver `@openspec/project.md` seção 8):
  - Models do domínio em `app/domains/<context>/` (ex: `app/domains/tenancy/condominium.rb` → `Tenancy::Condominium`)
  - Service objects em `app/services/<context>/` (ex: `app/services/tenancy/invite_member.rb` → `Tenancy::InviteMember`)
  - Policies em `app/policies/<context>/`, serializers em `app/serializers/<context>/` — mesmo padrão
  - Rails/Zeitwerk já registra `app/domains`, `app/services`, `app/policies`, `app/serializers` como raízes de autoload automaticamente (todo subdiretório direto de `app/`) — nenhuma configuração extra em `config/application.rb` é necessária ao criar um bounded context novo
  - `User` (Devise) fica **fora** de qualquer namespace de bounded context — é generic subdomain (autenticação), não domínio. A dependência flui sempre de um bounded context para `User` (`belongs_to`), nunca o contrário

---

## Convenções de código — Frontend

- Organização por feature em `src/features/` (não por tipo de arquivo)
- Cada feature tem: `ComponentName.tsx`, `useFeatureName.ts`, tipos inline ou `types.ts`
- Chamadas de API centralizadas em `src/lib/api.ts`
- Estado servidor via TanStack Query — sem duplicar em Zustand
- Zustand só para estado de UI global (ex: usuário autenticado, tema)
- Componentes shadcn/ui importados de `@/components/ui/`

---

## Convenções de commit

Seguir Conventional Commits com referência de task.

**Formato:**
```
<type>: TASK-XX — <descrição em português>
```

**Regras:**
- Referência da task (`TASK-XX`) vem logo após o tipo, antes do `—`
- Separador é `—` (em dash), não `-`
- Descrição sempre em **português**
- Sem parênteses em torno da referência da task

---

## Regras para o Claude Code

1. **Sempre rode os testes** após implementar uma tarefa. Nenhuma tarefa está concluída com testes quebrados.
2. **Peça confirmação** antes de rodar migrations destrutivas ou apagar arquivos.
3. **Uma tarefa por vez.** Não avance para a próxima sem confirmação explícita.
4. **Prefira editar** arquivos existentes a recriar do zero.
5. **Siga as convenções** definidas neste documento. Em caso de dúvida, pergunte antes de decidir.
6. **Commits atômicos** ao final de cada tarefa concluída.
7. **Tarefas são rastreadas via OpenSpec** (`openspec/changes/<nome>/tasks.md`) — marque os checkboxes conforme concluir cada uma.
8. **Módulos são isolados** — nunca criar dependência direta de código entre bounded contexts (Registry, Billing, Notice, Access, CommonArea). Comunicação apenas via Domain Events internos.
