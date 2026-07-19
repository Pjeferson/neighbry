## Why

O frontend hoje tem uma tela de "cadastro" que não funciona: `RegisterPage` chama `POST /api/v1/auth/sign_up` (Devise puro), que cria um `User` sem `Condominium` nem `Membership` — e como o login (`SessionsController#create`) exige `Membership` ativa antes de emitir JWT, esse usuário nunca consegue entrar no sistema. Além disso, `api.ts` não tem nenhum conceito de subdomínio/tenant, incompatível com a resolução de tenant por `Host` header que o backend já usa desde `add-tenancy`. Sem essa camada corrigida, nenhuma outra tela do frontend (Registry, Billing, Notice, CommonArea, Reservation) tem uma base funcional pra se conectar.

## What Changes

- **BREAKING**: remove o fluxo de auto-registro via `POST /api/v1/auth/sign_up` do frontend — não existe caso de uso válido no domínio para um `User` sem `Condominium`. `RegisterPage` deixa de existir nesse formato.
- Nova tela de cadastro (`/register`, servida no host genérico, sem subdomínio): cria um `Condominium` novo com seu admin, via `POST /api/v1/condominiums` (já existente, não muda).
- Nova seção "já tem conta?" no host genérico: usuário informa o identificador (slug) do condomínio, o frontend valida sua existência e redireciona para `<slug>.<host>/login`.
- Novo endpoint backend `GET /api/v1/condominiums/:slug` — checagem pública de existência de condomínio por slug, sem autenticação, sem depender de `ResolvesTenant` (é uma busca direta, não uma resolução por subdomínio de requisição).
- `LoginPage` só existe de fato dentro do subdomínio de um tenant; passa a distinguir os 3 erros que `SessionsController#create` já retorna (`condominium_not_found`, `invalid_credentials`, `no_active_membership_for_tenant`) em vez de uma mensagem genérica única.
- `api.ts`: `API_BASE` passa a ser calculado a partir de `window.location` (mesmo hostname, troca só a porta para a da API), com override via env var.
- Primeiros componentes shadcn/ui gerados (`components.json` já configurado, mas `components/ui/` está vazio) — Button, Input, Card, Label — usados nas telas novas, substituindo o HTML+Tailwind cru atual.

## Capabilities

### New Capabilities
(nenhuma — todo o comportamento novo estende a capability `tenancy` já existente)

### Modified Capabilities
- `tenancy`: adiciona checagem pública de existência de `Condominium` por slug, e formaliza (do lado de sistema observável, não só backend) que o fluxo de onboarding direciona o admin para autenticação no subdomínio do `Condominium` recém-criado.

## Impact

- Backend: novo endpoint `GET /api/v1/condominiums/:slug` em `Api::V1::CondominiumsController` (rota nova, sem novo bounded context, sem migration).
- Frontend: `RegisterPage`/`useAuth.signUp` removidos; novas telas de onboarding de condomínio e de busca por condomínio; `LoginPage` reescrita; `api.ts` reescrito para base de URL dinâmica; roteamento (`routes/`) reorganizado para diferenciar host genérico de subdomínio de tenant; primeiros componentes shadcn/ui instalados.
- Testes de frontend existentes (`RegisterPage.test.tsx`, `LoginPage.test.tsx`) ficam obsoletos e são substituídos.
- Fora de escopo: telas dos demais bounded contexts (cada um vira change própria depois desta), topologia de produção (domínio próprio/reverse proxy), fluxo de aceite de convite (`Tenancy::Invitation`) no frontend.
