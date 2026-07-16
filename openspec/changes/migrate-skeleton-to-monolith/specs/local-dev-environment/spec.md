## ADDED Requirements

### Requirement: Serviço Rails único
O ambiente local SHALL rodar um único serviço de aplicação Rails (`neighbry-api`), substituindo os três serviços independentes herdados do esqueleto anterior.

#### Scenario: Backend consolidado
- **WHEN** o diretório `services/` é inspecionado
- **THEN** existe apenas `services/neighbry-api/` como aplicação Rails; `services/payment-service/` e `services/receivables-service/` não existem

### Requirement: Banco de dados único
O ambiente local SHALL usar uma única instância PostgreSQL para o `neighbry-api`, em vez de um banco isolado por serviço.

#### Scenario: Topologia de banco no compose
- **WHEN** `docker-compose.yml` é inspecionado
- **THEN** existe apenas um serviço Postgres (não `postgres-account`, `postgres-payment`, `postgres-receivables` separados)

### Requirement: Sem mensageria entre serviços
O ambiente local SHALL NOT depender de um broker de mensagens (RabbitMQ) para comunicação entre módulos, já que a aplicação roda como processo único.

#### Scenario: Ausência de RabbitMQ
- **WHEN** `docker-compose.yml` e o `Gemfile` de `neighbry-api` são inspecionados
- **THEN** não há serviço `rabbitmq`, nem gems `bunny` ou `sneakers`, nem diretórios `app/consumers/` ou `app/publishers/` remanescentes do padrão RabbitMQ

### Requirement: Jobs assíncronos via Sidekiq
O ambiente local SHALL usar Sidekiq como backend de jobs assíncronos e agendados, substituindo o Solid Queue herdado.

#### Scenario: Worker de jobs
- **WHEN** `docker-compose.yml` é inspecionado
- **THEN** existe um serviço `sidekiq` com dependência explícita do serviço `redis`; não há gem `solid_queue` nem serviços `payment-jobs`/`receivables-jobs`

### Requirement: Mocks de integração como código interno
Simulações de integrações externas (validação de KYC/CPF-CNPJ, reconhecimento facial, geração de boleto/PIX) SHALL ser implementadas como service objects dentro de `neighbry-api`, não como processos HTTP separados.

#### Scenario: Ausência de processos mock externos
- **WHEN** o diretório `mocks/` e `docker-compose.yml` são inspecionados
- **THEN** não existem `mocks/kyc-mock/`, `mocks/spb-mock/`, `mocks/boleto-mock/` nem serviços correspondentes no compose

### Requirement: Frontend conecta direto ao backend
O frontend SHALL fazer requisições HTTP diretamente para `neighbry-api`, sem proxy reverso intermediário.

#### Scenario: Sem gateway
- **WHEN** o repositório é inspecionado
- **THEN** o diretório `api-gateway/` não existe, e `frontend/src/lib/api.ts` aponta `baseURL` para a porta do `neighbry-api`

### Requirement: Sem infraestrutura de e-mail
O ambiente local SHALL NOT incluir infraestrutura de envio/inspeção de e-mail (Mailhog) neste estágio do projeto.

#### Scenario: Ausência de Mailhog
- **WHEN** `docker-compose.yml` é inspecionado
- **THEN** não existe serviço `mailhog`

### Requirement: Sem suíte E2E Playwright
O ambiente local SHALL NOT incluir a suíte de testes E2E via Playwright herdada do esqueleto anterior.

#### Scenario: Ausência de infraestrutura Playwright
- **WHEN** o repositório é inspecionado
- **THEN** não existem `docker-compose.e2e.yml`, `frontend/playwright.config.ts`, arquivos `*.e2e.ts`, nem o controller/rotas de seed E2E (`/internal/e2e/seed`) no backend

### Requirement: Autenticação preservada
A infraestrutura de autenticação (Devise + devise-jwt, model `User`, `JwtDenylist`) SHALL ser preservada como parte da migração, por não ser específica do domínio CredFlow.

#### Scenario: Auth funcional após a migração
- **WHEN** `neighbry-api` sobe via `docker compose up`
- **THEN** os endpoints Devise (`POST /api/v1/auth/sign_up`, `POST /api/v1/auth/sign_in`, `DELETE /api/v1/auth/sign_out`) respondem normalmente
