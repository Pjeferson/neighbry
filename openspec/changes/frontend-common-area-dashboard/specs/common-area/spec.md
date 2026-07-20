## MODIFIED Requirements

### Requirement: Listagem de CommonArea é aberta a qualquer Membership ativo
O sistema SHALL permitir que qualquer `User` com `Tenancy::Membership` ativo no `Condominium` (qualquer `role`) consulte a listagem de `CommonArea` desse condomínio.

#### Scenario: Morador consulta a listagem de espaços comuns
- **WHEN** um `User` com `Membership(role: resident, status: active)` no `Condominium` consulta a listagem de `CommonArea`
- **THEN** a consulta é permitida

#### Scenario: Staff consulta a listagem de espaços comuns
- **WHEN** um `User` com `Membership(role: manager, status: active)` ou `Membership(role: service_provider, status: active)` no `Condominium` consulta a listagem de `CommonArea`
- **THEN** a consulta é permitida

#### Scenario: Usuário sem Membership ativo no condomínio não consulta a listagem
- **WHEN** um `User` sem `Membership` ativo no `Condominium` tenta consultar a listagem de `CommonArea` desse condomínio
- **THEN** a consulta é rejeitada
