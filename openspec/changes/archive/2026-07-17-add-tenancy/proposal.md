## Why

O Neighbry é multi-tenant: uma única instância atende vários condomínios. Hoje o backend só tem autenticação genérica (`User` via Devise/JWT) — não existe nenhum conceito de condomínio, nem de "quem pode acessar qual condomínio e com que poder". Sem essa fundação, nenhum bounded context de domínio (Registry, Billing, Notice, Access, CommonArea) tem como escopar seus dados por tenant, e não há como logar já sabendo em qual condomínio se está atuando.

Esta change introduz esse alicerce antes de qualquer bounded context de domínio ser implementado — `Registry` (Building/Unit/Person/Occupancy), a próxima change planejada, depende de `Condominium` já existir.

## What Changes

- Novo bounded context `Tenancy`, primeiro módulo de domínio do projeto (introduz a estrutura `app/domains/` que o `CLAUDE.md` previa).
- Novo agregado `Condominium` — raiz da hierarquia multi-tenant, com slug único usado como subdomínio de login.
- Novo agregado `Membership` — vincula `User` a `Condominium` com um papel de acesso ao sistema (`admin | manager | doorman | resident`); no v1, um `User` pertence a **no máximo um** `Condominium`, com **um único** papel (multiplicidade fica para uma possível v2).
- Novo fluxo `Invitation` — convite único e seguro por token; em desenvolvimento o link é devolvido na resposta da API (sem infraestrutura de email, conforme `local-dev-environment` já define); só a própria pessoa convidada define sua senha.
- Login passa a ser resolvido por subdomínio (`<slug>.neighbry.com/login`) — falha se o `User` não tiver `Membership` ativo naquele `Condominium`.
- Novo fluxo de onboarding de condomínio (`create-condominium`), fora da lógica de subdomínio, que cria `Condominium` + primeiro `User` + `Membership(role: admin)` numa única operação.
- `Membership` ganha um campo de status (`active | revoked`) preparado para ser revogado por evento de domínio vindo de `Registry` no futuro (não implementado nesta change).
- **BREAKING**: nenhuma — não há bounded contexts de domínio existentes para quebrar.

## Capabilities

### New Capabilities
- `tenancy`: multi-tenant condominium identity — `Condominium`, `Membership`, `Invitation`, login por subdomínio, onboarding de condomínio.

### Modified Capabilities
- (nenhuma — `local-dev-environment` não muda requisito, só passa a ser referenciada pela decisão de exibir o token de convite em vez de enviar email)

## Impact

- **Backend**: novo namespace `app/domains/tenancy/` (models, service objects, policies); novas migrations (`condominiums`, `memberships`, `invitations`); novas rotas `/api/v1/...` (login por subdomínio, criação de condomínio, aceite de convite); Devise/`User` permanece inalterado, mas passa a ser referenciado por `Membership` via `user_id`.
- **Frontend**: fluxo de login precisa resolver subdomínio; tela de aceite de convite; tela de criação de condomínio.
- **Sem impacto** em Billing/Notice/Access/CommonArea — ainda não existem.
